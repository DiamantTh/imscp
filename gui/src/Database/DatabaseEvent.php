<?php
/**
 * i-MSCP - internet Multi Server Control Panel
 * Copyright (C) 2010-2019 by Laurent Declercq <l.declercq@nuxwin.com>
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

/**
 * @noinspection
 * PhpDocMissingThrowsInspection
 * PhpUnhandledExceptionInspection
 * PhpUnused
 */

declare(strict_types=1);

namespace iMSCP\Database;

use iMSCP\Event\Event;

/**
 * Class DatabaseEvent
 * @package iMSCP\Database
 */
class DatabaseEvent extends Event
{
    /**
     * Returns the database instance in which this event was dispatched.
     *
     * @return DatabaseMySQL
     */
    public function getDb()
    {
        return $this->getParam('context');
    }

    /**
     * Returns the query string.
     *
     * @return string
     */
    public function getQueryString()
    {
        return $this->getParam('query');
    }
}
