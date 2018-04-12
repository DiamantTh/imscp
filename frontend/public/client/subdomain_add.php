<?php
/**
 * i-MSCP - internet Multi Server Control Panel
 * Copyright (C) 2010-2018 by Laurent Declercq <l.declercq@nuxwin.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

use iMSCP\PHPini;
use iMSCP\TemplateEngine;
use iMSCP_Events as Events;
use iMSCP_Events_Event as Event;
use iMSCP_Registry as Registry;

/**
 * Get domains list
 *
 * @return array Domains list
 */
function getDomainsList()
{
    static $domainsList = NULL;

    if (NULL !== $domainsList) {
        return $domainsList;
    }

    $mainDmnProps = get_domain_default_props($_SESSION['user_id']);
    $domainsList = [[
        'name'        => $mainDmnProps['domain_name'],
        'id'          => $mainDmnProps['domain_id'],
        'type'        => 'dmn',
        'mount_point' => '/',
        'url_forward' => $mainDmnProps['url_forward']
    ]];
    $stmt = exec_query(
        "
            SELECT CONCAT(t1.subdomain_name, '.', t2.domain_name) AS name, t1.subdomain_id AS id, 'sub' AS type, t1.subdomain_mount AS mount_point,
                t1.subdomain_url_forward AS url_forward
            FROM subdomain AS t1
            JOIN domain AS t2 USING(domain_id)
            WHERE t1.domain_id = ?
            AND t1.subdomain_status = 'ok'
            UNION ALL
            SELECT alias_name, alias_id, 'als', alias_mount, url_forward
            FROM domain_aliases
            WHERE domain_id = ?
            AND alias_status = 'ok'
            UNION ALL
            SELECT CONCAT(t1.subdomain_alias_name, '.', t2.alias_name), t1.subdomain_alias_id, 'alssub', t1.subdomain_alias_mount,
                t1.subdomain_alias_url_forward AS url_forward
            FROM subdomain_alias AS t1
            JOIN domain_aliases AS t2 USING(alias_id)
            WHERE t2.domain_id = ?
            AND t1.subdomain_alias_status = 'ok'
        ",
        [$mainDmnProps['domain_id'], $mainDmnProps['domain_id'], $mainDmnProps['domain_id']]
    );

    if ($stmt->rowCount()) {
        $domainsList = array_merge($domainsList, $stmt->fetchAll());
        usort($domainsList, function ($a, $b) {
            return strnatcmp(decode_idna($a['name']), decode_idna($b['name']));
        });
    }

    return $domainsList;
}

/**
 * Add subdomain
 *
 * @return bool TRUE on success, FALSE on failure
 */
function addSubdomain()
{
    global $mainDmnProps;

    // Basic check
    if (empty($_POST['subdomain_name'])) {
        set_page_message(tr('You must enter a subdomain name.'), 'error');
        return false;
    }

    if (empty($_POST['domain_name'])) {
        showBadRequestErrorPage();
    }

    // Check for parent domain
    $domainName = mb_strtolower(clean_input($_POST['domain_name']));
    $domainType = $domainId = NULL;
    $domainList = getDomainsList();

    foreach ($domainList as $domain) {
        if (($domain['type'] == 'dmn' || $domain['type'] == 'als') && $domain['name'] == $domainName) {
            $domainType = $domain['type'];
            $domainId = $domain['id'];
        }
    }

    if (NULL === $domainType) {
        showBadRequestErrorPage();
    }

    $subLabel = mb_strtolower(clean_input($_POST['subdomain_name']));
    if ($subLabel == 'www' || strpos($subLabel, 'www.') === 0) {
        set_page_message(tr('%s is not allowed as subdomain label.', "<strong>www</strong>"), 'error');
        return false;
    }

    $subdomainName = $subLabel . '.' . $domainName;
    // Check for subdomain syntax
    if (!isValidDomainName($subdomainName)) {
        set_page_message(tr('Subdomain name is not valid.'), 'error');
        return false;
    }

    // Ensure that this subdomain doesn't already exists as domain or domain alias
    $stmt = exec_query(
        '
            SELECT domain_id FROM domain WHERE domain_name = ?
            UNION ALL
            SELECT alias_id FROM domain_aliases WHERE alias_name = ?
        ',
        [$subdomainName, $subdomainName]
    );
    if ($stmt->rowCount()) {
        set_page_message(tr('Subdomain %s is unavailable.', "<strong>$subdomainName</strong>"), 'error');
        return false;
    }

    // Check for domain alias IP addresses
    $subdomainIps = [];
    if (empty($_POST['subdomain_ips'])) {
        set_page_message(tohtml(tr('You must assign at least one IP address to that subdomain.')), 'error');
        return false;
    } elseif (!is_array($_POST['subdomain_ips'])) {
        showBadRequestErrorPage();
    } else {
        $clientIps = explode(',', $mainDmnProps['domain_client_ips']);
        $subdomainIps = array_intersect($_POST['subdomain_ips'], $clientIps);
        if (count($subdomainIps) < count($_POST['subdomain_ips'])) {
            // Situation where unknown IP address identifier has been submitten
            showBadRequestErrorPage();
        }
    }

    $subLabelAscii = encode_idna($subLabel);
    $subdomainNameAscii = encode_idna($subdomainName);

    // Check for subdomain existence
    foreach ($domainList as $domain) {
        if ($domain['name'] == $subdomainNameAscii) {
            set_page_message(tr('Subdomain %s already exist.', "<strong>$subdomainName</strong>"), 'error');
            return false;
        }
    }

    // Set default mount point
    if ($domainType == 'dmn') {
        $mountPoint = in_array($subLabelAscii, ['backups', 'cgi-bin', 'errors', 'htdocs', 'logs', 'phptmp'], true)
            ? "/sub_$subLabelAscii" : "/$subLabelAscii";
    } else {
        $mountPoint = in_array($subLabelAscii, ['cgi-bin', 'htdocs'], true) ?
            "/$domainName/sub_$subLabelAscii" : "/$domainName/$subLabelAscii";
    }

    // Check for shared mount point option
    if (isset($_POST['shared_mount_point']) && $_POST['shared_mount_point'] == 'yes') { // We are safe here
        isset($_POST['shared_mount_point_domain']) or showBadRequestErrorPage();

        $sharedMountPointDomain = clean_input($_POST['shared_mount_point_domain']);

        // Get shared mount point
        foreach ($domainList as $domain) {
            if ($domain['name'] == $sharedMountPointDomain) {
                $mountPoint = $domain['mount_point'];
            }
        }
    }

    // Default values
    $documentRoot = '/htdocs';
    $forwardUrl = 'no';
    $forwardType = NULL;
    $forwardHost = 'Off';

    // Check for URL forwarding option
    if (isset($_POST['url_forwarding']) && $_POST['url_forwarding'] == 'yes' && isset($_POST['forward_type'])
        && in_array($_POST['forward_type'], ['301', '302', '303', '307', 'proxy'], true)
    ) {
        isset($_POST['forward_url_scheme']) && isset($_POST['forward_url']) or showBadRequestErrorPage();

        $forwardUrl = clean_input($_POST['forward_url_scheme']) . clean_input($_POST['forward_url']);
        $forwardType = clean_input($_POST['forward_type']);

        if ($forwardType == 'proxy' && isset($_POST['forward_host'])) {
            $forwardHost = 'On';
        }

        try {
            try {
                $uri = iMSCP_Uri_Redirect::fromString($forwardUrl);
            } catch (Zend_Uri_Exception $e) {
                throw new iMSCP_Exception(tr('Forward URL %s is not valid.', "<strong>$forwardUrl</strong>"));
            }

            $uri->setHost(encode_idna(mb_strtolower($uri->getHost()))); // Normalize URI host
            $uri->setPath(rtrim(utils_normalizePath($uri->getPath()), '/') . '/'); // Normalize URI path

            if ($uri->getHost() == $subdomainNameAscii && ($uri->getPath() == '/' && in_array($uri->getPort(), ['', 80, 443]))) {
                throw new iMSCP_Exception(
                    tr('Forward URL %s is not valid.', "<strong>$forwardUrl</strong>") . ' '
                    . tr('Subdomain %s cannot be forwarded on itself.', "<strong>$subdomainName</strong>")
                );
            }

            if ($forwardType == 'proxy') {
                $port = $uri->getPort();
                if ($port && $port < 1025) {
                    throw new iMSCP_Exception(tr('Unallowed port in forward URL. Only ports above 1024 are allowed.', 'error'));
                }
            }

            $forwardUrl = $uri->getUri();
        } catch (Exception $e) {
            set_page_message($e->getMessage(), 'error');
            return false;
        }
    }

    /** @var iMSCP_Database $db */
    $db = Registry::get('iMSCP_Application')->getDatabase();

    try {
        $db->beginTransaction();

        Registry::get('iMSCP_Application')->getEventsManager()->dispatch(iMSCP_Events::onBeforeAddSubdomain, [
            'subdomainName'  => $subdomainName,
            'subdomainIps'   => $subdomainIps,
            'subdomainType'  => $domainType,
            'parentDomainId' => $domainId,
            'mountPoint'     => $mountPoint,
            'documentRoot'   => $documentRoot,
            'forwardUrl'     => $forwardUrl,
            'forwardType'    => $forwardType,
            'forwardHost'    => $forwardHost,
            'customerId'     => $_SESSION['user_id']
        ]);

        if ($domainType == 'als') {
            $query = "
                INSERT INTO subdomain_alias (
                    alias_id, subdomain_alias_name, subdomain_alias_ips, subdomain_alias_mount, subdomain_alias_document_root,
                    subdomain_alias_url_forward, subdomain_alias_type_forward, subdomain_alias_host_forward, subdomain_alias_status
                ) VALUES (
                    ?, ?, ?, ?, ?, ?, ?, ?, 'toadd'
                )
            ";
        } else {
            $query = "
                INSERT INTO subdomain (
                    domain_id, subdomain_name, subdomain_ips, subdomain_mount, subdomain_document_root, subdomain_url_forward, subdomain_type_forward,
                    subdomain_host_forward, subdomain_status
                ) VALUES (
                    ?, ?, ?, ?, ?, ?, ?, ?, 'toadd'
                )
            ";
        }

        exec_query($query, [
            $domainId, $subLabelAscii, implode(',', $subdomainIps), $mountPoint, $documentRoot, $forwardUrl, $forwardType, $forwardHost
        ]);

        $subdomainId = $db->lastInsertId();

        // Create the phpini entry for that subdomain
        $phpini = PHPini::getInstance();
        $phpini->loadResellerPermissions($_SESSION['user_created_by']);
        $phpini->loadClientPermissions($_SESSION['user_id']);

        if ($phpini->getClientPermission('phpiniConfigLevel') != 'per_site') {
            // Set INI options, based on parent domain
            if ($domainType == 'dmn') {
                $phpini->loadIniOptions($_SESSION['user_id'], $mainDmnProps['domain_id'], 'dmn');
            } else {
                $phpini->loadIniOptions($_SESSION['user_id'], $domainId, 'als');
            }
        } else {
            // Set default INI options
            $phpini->loadIniOptions();
        }

        $phpini->saveIniOptions($_SESSION['user_id'], $subdomainId, $domainType == 'dmn' ? 'sub' : 'subals');

        createDefaultMailAccounts(
            $mainDmnProps['domain_id'],
            iMSCP_Authentication::getInstance()->getIdentity()->email,
            $subdomainNameAscii,
            $domainType == 'dmn' ? MT_SUBDOM_FORWARD : MT_ALSSUB_FORWARD, $subdomainId
        );

        Registry::get('iMSCP_Application')->getEventsManager()->dispatch(iMSCP_Events::onAfterAddSubdomain, [
            'subdomainName'  => $subdomainName,
            'subdomainIps'   => $subdomainIps,
            'subdomainType'  => $domainType,
            'parentDomainId' => $domainId,
            'mountPoint'     => $mountPoint,
            'documentRoot'   => $documentRoot,
            'forwardUrl'     => $forwardUrl,
            'forwardType'    => $forwardType,
            'forwardHost'    => $forwardHost,
            'customerId'     => $_SESSION['user_id'],
            'subdomainId'    => $subdomainId
        ]);

        $db->commit();
        send_request();
        write_log(sprintf('A new subdomain (%s) has been created by %s', $subdomainName, $_SESSION['user_logged']), E_USER_NOTICE);
        return true;
    } catch (iMSCP_Exception $e) {
        $db->rollBack();
        write_log(sprintf('System was unable to create the %s subdomain: %s', $subdomainName, $e->getMessage()), E_USER_ERROR);
        set_page_message('Could not create subdomain. An unexpected error occurred.', 'error');
        return false;
    }
}

/**
 * Generate page
 *
 * @param $tpl TemplateEngine
 * @return void
 */
function generatePage($tpl)
{
    $forwardType = isset($_POST['forward_type']) && in_array($_POST['forward_type'], ['301', '302', '303', '307', 'proxy'], true)
        ? $_POST['forward_type'] : '302';
    $forwardHost = $forwardType == 'proxy' && isset($_POST['forward_host']) ? 'On' : 'Off';

    $tpl->assign([
        'SUBDOMAIN_NAME'     => isset($_POST['subdomain_name']) ? tohtml($_POST['subdomain_name']) : '',
        'FORWARD_URL_YES'    => isset($_POST['url_forwarding']) && $_POST['url_forwarding'] == 'yes' ? ' checked' : '',
        'FORWARD_URL_NO'     => isset($_POST['url_forwarding']) && $_POST['url_forwarding'] == 'yes' ? '' : ' checked',
        'HTTP_YES'           => isset($_POST['forward_url_scheme']) && $_POST['forward_url_scheme'] == 'http://' ? ' selected' : '',
        'HTTPS_YES'          => isset($_POST['forward_url_scheme']) && $_POST['forward_url_scheme'] == 'https://' ? ' selected' : '',
        'FORWARD_URL'        => isset($_POST['forward_url']) ? tohtml($_POST['forward_url']) : '',
        'FORWARD_TYPE_301'   => $forwardType == '301' ? ' checked' : '',
        'FORWARD_TYPE_302'   => $forwardType == '302' ? ' checked' : '',
        'FORWARD_TYPE_303'   => $forwardType == '303' ? ' checked' : '',
        'FORWARD_TYPE_307'   => $forwardType == '307' ? ' checked' : '',
        'FORWARD_TYPE_PROXY' => $forwardType == 'proxy' ? ' checked' : '',
        'FORWARD_HOST'       => $forwardHost == 'On' ? ' checked' : ''
    ]);

    $shareableMountpointCount = 0;
    foreach (getDomainsList() as $domain) {
        if ($domain['url_forward'] == 'no') {
            $shareableMountpointCount++;
        }

        $tpl->assign([
            'DOMAIN_NAME'          => tohtml($domain['name']),
            'DOMAIN_NAME_UNICODE'  => tohtml(decode_idna($domain['name'])),
            'DOMAIN_NAME_SELECTED' => isset($_POST['domain_name']) && $_POST['domain_name'] == $domain['name'] ? ' selected' : '',
        ]);

        if ($domain['type'] == 'dmn' || $domain['type'] == 'als') {
            $tpl->parse('PARENT_DOMAIN', '.parent_domain');
        }

        if ($domain['url_forward'] == 'no') {
            $tpl->assign(
                'SHARED_MOUNT_POINT_DOMAIN_SELECTED',
                isset($_POST['shared_mount_point_domain']) && $_POST['shared_mount_point_domain'] == $domain['name'] ? ' selected' : ''
            );
            $tpl->parse('SHARED_MOUNT_POINT_DOMAIN', '.shared_mount_point_domain');
        }
    }

    if ($shareableMountpointCount == 0) {
        $tpl->assign('SHARED_MOUNT_POINT_OPTION_JS', '');
        $tpl->assign('SHARED_MOUNT_POINT_OPTION', '');
    } else {
        $tpl->assign([
            'SHARED_MOUNT_POINT_YES' => isset($_POST['shared_mount_point']) && $_POST['shared_mount_point'] == 'yes' ? ' checked' : '',
            'SHARED_MOUNT_POINT_NO'  => isset($_POST['shared_mount_point']) && $_POST['shared_mount_point'] == 'yes' ? '' : ' checked'
        ]);
    }

    client_generate_ip_list(
        $tpl, $_SESSION['user_id'], isset($_POST['subdomain_ips']) && is_array($_POST['subdomain_ips']) ? $_POST['subdomain_ips'] : []
    );
}

require_once 'imscp-lib.php';

check_login('user');
Registry::get('iMSCP_Application')->getEventsManager()->dispatch(iMSCP_Events::onClientScriptStart);
customerHasFeature('subdomains') or showBadRequestErrorPage();

$mainDmnProps = get_domain_default_props($_SESSION['user_id']);
$subdomainsCount = get_customer_subdomains_count($mainDmnProps['domain_id']);

if ($mainDmnProps['domain_subd_limit'] != 0 && $subdomainsCount >= $mainDmnProps['domain_subd_limit']) {
    set_page_message(tr('You have reached the maximum number of subdomains allowed by your subscription.'), 'warning');
    redirectTo('domains_manage.php');
}

if (!empty($_POST) && addSubdomain()) {
    set_page_message(tr('Subdomain successfully scheduled for addition.'), 'success');
    redirectTo('domains_manage.php');
}

$tpl = new TemplateEngine();
$tpl->define([
    'layout'                       => 'shared/layouts/ui.tpl',
    'page'                         => 'client/subdomain_add.tpl',
    'page_message'                 => 'layout',
    'parent_domain'                => 'page',
    'ip_entry'                     => 'page',
    'shared_mount_point_option_js' => 'page',
    'shared_mount_point_option'    => 'page',
    'shared_mount_point_domain'    => 'shared_mount_point_option'
]);
$tpl->assign([
    'TR_PAGE_TITLE'                 => tohtml(tr('Client / Domains / Add Subdomain')),
    'TR_SUBDOMAIN'                  => tohtml(tr('Subdomain')),
    'TR_SUBDOMAIN_NAME'             => tohtml(tr('Name')),
    'TR_SUBDOMAIN_IPS'              => tohtml(tr('IP addresses')),
    'TR_SHARED_MOUNT_POINT'         => tohtml(tr('Shared mount point')),
    'TR_SHARED_MOUNT_POINT_TOOLTIP' => tohtml(tr('Allows to share the mount point of another domain.'), 'htmlAttr'),
    'TR_URL_FORWARDING'             => tohtml(tr('URL forwarding')),
    'TR_URL_FORWARDING_TOOLTIP'     => tohtml(tr('Allows to forward any request made to this domain to a specific URL.'), 'htmlAttr'),
    'TR_FORWARD_TO_URL'             => tohtml(tr('Forward to URL')),
    'TR_YES'                        => tohtml(tr('Yes')),
    'TR_NO'                         => tohtml(tr('No')),
    'TR_HTTP'                       => tohtml('http://'),
    'TR_HTTPS'                      => tohtml('https://'),
    'TR_FORWARD_TYPE'               => tohtml(tr('Forward type')),
    'TR_301'                        => tohtml('301'),
    'TR_302'                        => tohtml('302'),
    'TR_303'                        => tohtml('303'),
    'TR_307'                        => tohtml('307'),
    'TR_PROXY'                      => tohtml(tr('Proxy')),
    'TR_PROXY_PRESERVE_HOST'        => tohtml(tr('Preserve Host')),
    'TR_ADD'                        => tohtml(tr('Add'), 'htmlAttr'),
    'TR_CANCEL'                     => tohtml(tr('Cancel'))
]);

Registry::get('iMSCP_Application')->getEventsManager()->registerListener(Events::onGetJsTranslations, function (Event $e) {
    $translations = $e->getParam('translations');
    $translations['core']['available'] = tr('Available');
    $translations['core']['assigned'] = tr('Assigned');
});

generateNavigation($tpl);
generatePage($tpl);
generatePageMessage($tpl);

$tpl->parse('LAYOUT_CONTENT', 'page');
Registry::get('iMSCP_Application')->getEventsManager()->dispatch(iMSCP_Events::onClientScriptEnd, ['templateEngine' => $tpl]);
$tpl->prnt();

unsetMessages();
