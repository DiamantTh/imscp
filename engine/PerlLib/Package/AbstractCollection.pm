=head1 NAME

 Package::AbstractCollection - Abstract class for i-MSCP package collection

=cut

# i-MSCP - internet Multi Server Control Panel
# Copyright (C) 2010-2018 by Laurent Declercq <l.declercq@nuxwin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package Package::AbstractCollection;

use strict;
use warnings;
use autouse 'iMSCP::Dialog::InputValidation' => qw/ isOneOfStringsInList /;
use Carp qw/ confess /;
use iMSCP::Debug qw/ debug /;
use iMSCP::Dir;
use iMSCP::Getopt;
use parent 'Package::Abstract';

=head1 DESCRIPTION

 Abstract class for i-MSCP package collection.
 
 An i-MSCP package collection gather in-MSCP packages which serve the same purpose.
 
 This class is meant to be subclassed by i-MSCP package collection classes.

=head1 PUBLIC METHODS

=over 4

=item registerInstallerDialogs( $dialogs )

 See iMSCP::AbstractInstallerActions::registerInstallerDialogs()

=cut

sub registerInstallerDialogs
{
    my ( $self, $dialogs ) = @_;

    push @{ $dialogs }, sub { $self->_askForPackages( @_ ) };
    0;
}

=item preinstall( )

 See iMSCP::AbstractInstallerActions::preinstall()
 
 This will first uninstall unselected packages

=cut

sub preinstall
{
    my ( $self ) = @_;

    for my $package ( @{ $self->getUnselectedPackages() } ) {
        debug( sprintf( 'Executing uninstall action on %s', ref $package ));
        $package->uninstall();
    }

    $self->_executeActionOnSelectedPackages( 'preinstall' );
}

=item install( )

 See iMSCP::AbstractInstallerActions::install()

=cut

sub install
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'install' );
}

=item postinstall( )

 See iMSCP::AbstractInstallerActions::postinstall()

=cut

sub postinstall
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'postinstall' );
}

=item preuninstall( )

 See iMSCP::AbstractInstallerActions::preuninstall()

=cut

sub preuninstall
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'preuninstall' );
}

=item postuninstall( )

 See iMSCP::AbstractInstallerActions::postuninstall()

=cut

sub postuninstall
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'postuninstall' );
}

=item setEnginePermissions( )

 See iMSCP::AbstractInstallerActions::setEnginePermissions()

=cut

sub setEnginePermissions
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'setEnginePermissions' );
}

=item setGuiPermissions( )

 See iMSCP::AbstractInstallerActions::setGuiPermissions()

=cut

sub setGuiPermissions
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'setGuiPermissions' );
}

=item dpkgPostInvokeTasks( )

 See iMSCP::AbstractInstallerActions::dpkgPostInvokeTasks()

=cut

sub dpkgPostInvokeTasks
{
    my ( $self ) = @_;

    $self->_executeActionOnSelectedPackages( 'dpkgPostInvokeTasks' );
}

=item preaddDmn( \%data )

 See iMSCP::AbstractModuleActionspreaddDmn()

=cut

sub preaddDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddDmn', $data );
}

=item addDmn( \%data )

 See iMSCP::AbstractModuleActionsaddDmn()

=cut

sub addDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addDmn', $data );
}

=item postaddDmn( \%data )

 See iMSCP::AbstractModuleActionspostaddDmn()

=cut

sub postaddDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddDmn', $data );
}

=item predeleteDmn( \%data )

 See iMSCP::AbstractModuleActionspredeleteDmn()

=cut

sub predeleteDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteDmn', $data );
}

=item deleteDmn( \%data )

 See iMSCP::AbstractModuleActionsdeleteDmn()

=cut

sub deleteDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteDmn', $data );
}

=item postdeleteDmn( \%data )

 See iMSCP::AbstractModuleActionspostdeleteDmn()

=cut

sub postdeleteDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteDmn', $data );
}

=item prerestoreDmn( \%data )

 See iMSCP::AbstractModuleActionsprerestoreDmn()

=cut

sub prerestoreDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'prerestoreDmn', $data );
}

=item restoreDmn( \%data )

 See iMSCP::AbstractModuleActionsrestoreDmn()

=cut

sub restoreDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'restoreDmn', $data );
}

=item postrestoreDmn( \%data )

 See iMSCP::AbstractModuleActionspostrestoreDmn()

=cut

sub postrestoreDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postrestoreDmn', $data );
}

=item predisableDmn( \%data )

 See iMSCP::AbstractModuleActionspredisableDmn()

=cut

sub predisableDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableDmn', $data );
}

=item disableDmn( \%data )

 See iMSCP::AbstractModuleActionsdisableDmn()

=cut

sub disableDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableDmn', $data );
}

=item postdisableDmn( \%data )

 See iMSCP::AbstractModuleActionspostdisableDmn()

=cut

sub postdisableDmn
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableDmn', $data );
}

=item preaddCustomDNS( \%data )

 See iMSCP::AbstractModuleActionspreaddCustomDNS()

=cut

sub preaddCustomDNS
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddCustomDNS', $data );
}

=item addCustomDNS( \%data )

 See iMSCP::AbstractModuleActionsaddCustomDNS()

=cut

sub addCustomDNS
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addCustomDNS', $data );
}

=item postaddCustomDNS( \%data )

 See iMSCP::AbstractModuleActionspostaddCustomDNS()

=cut

sub postaddCustomDNS
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddCustomDNS', $data );
}

=item preaddFtpUser( \%data )

 See iMSCP::AbstractModuleActionspreaddFtpUser()

=cut

sub preaddFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddFtpUser', $data );
}

=item addFtpUser( \%data )

 See iMSCP::AbstractModuleActionsaddFtpUser()

=cut

sub addFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addFtpUser', $data );
}

=item postaddFtpUser( \%data )

 See iMSCP::AbstractModuleActionspostaddFtpUser()

=cut

sub postaddFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddFtpUser', $data );
}

=item predeleteFtpUser( \%data )

 See iMSCP::AbstractModuleActionspredeleteFtpUser()

=cut

sub predeleteFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteFtpUser', $data );
}

=item deleteFtpUser( \%data )

 See iMSCP::AbstractModuleActionsdeleteFtpUser()

=cut

sub deleteFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteFtpUser', $data );
}

=item postdeleteFtpUser( \%data )

 See iMSCP::AbstractModuleActionspostdeleteFtpUser()

=cut

sub postdeleteFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteFtpUser', $data );
}

=item predisableFtpUser( \%data )

 See iMSCP::AbstractModuleActionspredisableFtpUser()

=cut

sub predisableFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableFtpUser', $data );
}

=item disableFtpUser( \%data )

 See iMSCP::AbstractModuleActionsdisableFtpUser()

=cut

sub disableFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableFtpUser', $data );
}

=item postdisableFtpUser( \%data )

 See iMSCP::AbstractModuleActionspostdisableFtpUser()

=cut

sub postdisableFtpUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableFtpUser', $data );
}

=item preaddHtaccess( \%data )

 See iMSCP::AbstractModuleActionspreaddHtaccess()

=cut

sub preaddHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddHtaccess', $data );
}

=item addHtaccess( \%data )

 See iMSCP::AbstractModuleActionsaddHtaccess()

=cut

sub addHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addHtaccess', $data );
}

=item postaddHtaccess( \%data )

 See iMSCP::AbstractModuleActionspostaddHtaccess()

=cut

sub postaddHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteHtaccess', $data );
}

=item predeleteHtaccess( \%data )

 See iMSCP::AbstractModuleActionspredeleteHtaccess()

=cut

sub predeleteHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteHtaccess', $data );
}

=item deleteHtaccess( \%data )

 See iMSCP::AbstractModuleActionsdeleteHtaccess()

=cut

sub deleteHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteHtaccess', $data );
}

=item postdeleteHtaccess( \%data )

 See iMSCP::AbstractModuleActionspostdeleteHtaccess()

=cut

sub postdeleteHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteHtaccess', $data );
}

=item predisableHtaccess( \%data )

 See iMSCP::AbstractModuleActionspredisableHtaccess()

=cut

sub predisableHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableHtaccess', $data );
}

=item disableHtaccess( \%data )

 See iMSCP::AbstractModuleActionsdisableHtaccess()

=cut

sub disableHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableHtaccess', $data );
}

=item postdisableHtaccess( \%data )

 See iMSCP::AbstractModuleActionspostdisableHtaccess()

=cut

sub postdisableHtaccess
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableHtaccess', $data );
}

=item preaddHtgroup( \%data )

 See iMSCP::AbstractModuleActionspreaddHtgroup()

=cut

sub preaddHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddHtgroup', $data );
}

=item addHtgroup( \%data )

 See iMSCP::AbstractModuleActionsaddHtgroup()

=cut

sub addHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addHtgroup', $data );
}

=item postaddHtgroup( \%data )

 See iMSCP::AbstractModuleActionspostaddHtgroup()

=cut

sub postaddHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddHtgroup', $data );
}

=item predeleteHtgroup( \%data )

 See iMSCP::AbstractModuleActionspredeleteHtgroup()

=cut

sub predeleteHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteHtgroup', $data );
}

=item deleteHtgroup( \%data )

 See iMSCP::AbstractModuleActionsdeleteHtgroup()

=cut

sub deleteHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteHtgroup', $data );
}

=item postdeleteHtgroup( \%data )

 See iMSCP::AbstractModuleActionspostdeleteHtgroup()

=cut

sub postdeleteHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteHtgroup', $data );
}

=item predisableHtgroup( \%data )

 See iMSCP::AbstractModuleActionspredisableHtgroup()

=cut

sub predisableHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableHtgroup', $data );
}

=item disableHtgroup( \%data )

 See iMSCP::AbstractModuleActionsdisableHtgroup()

=cut

sub disableHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableHtgroup', $data );
}

=item postdisableHtgroup( \%data )

 See iMSCP::AbstractModuleActionspostdisableHtgroup()

=cut

sub postdisableHtgroup
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableHtgroup', $data );
}

=item preaddHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspreaddHtpasswd()

=cut

sub preaddHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddHtpasswd', $data );
}

=item addHtpasswd( \%data )

 See iMSCP::AbstractModuleActionsaddHtpasswd()

=cut

sub addHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addHtpasswd', $data );
}

=item postaddHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspostaddHtpasswd()

=cut

sub postaddHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddHtpasswd', $data );
}

=item predeleteHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspredeleteHtpasswd()

=cut

sub predeleteHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteHtpasswd', $data );
}

=item deleteHtpasswd( \%data )

 See iMSCP::AbstractModuleActionsdeleteHtpasswd()

=cut

sub deleteHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteHtpasswd', $data );
}

=item postdeleteHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspostdeleteHtpasswd()

=cut

sub postdeleteHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteHtpasswd', $data );
}

=item predisableHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspredisableHtpasswd()

=cut

sub predisableHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableHtpasswd', $data );
}

=item disableHtpasswd( \%data )

 See iMSCP::AbstractModuleActionsdisableHtpasswd()

=cut

sub disableHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableHtpasswd', $data );
}

=item postdisableHtpasswd( \%data )

 See iMSCP::AbstractModuleActionspostdisableHtpasswd()

=cut

sub postdisableHtpasswd
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableHtpasswd', $data );
}

=item preaddMail( \%data )

 See iMSCP::AbstractModuleActionspreaddMail()

=cut

sub preaddMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddMail', $data );
}

=item addMail( \%data )

 See iMSCP::AbstractModuleActionsaddMail()

=cut

sub addMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addMail', $data );
}

=item postaddMail( \%data )

 See iMSCP::AbstractModuleActionspostaddMail()

=cut

sub postaddMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddMail', $data );
}

=item predeleteMail( \%data )

 See iMSCP::AbstractModuleActionspredeleteMail()

=cut

sub predeleteMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteMail', $data );
}

=item deleteMail( \%data )

 See iMSCP::AbstractModuleActionsdeleteMail()

=cut

sub deleteMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteMail', $data );
}

=item postdeleteMail( \%data )

 See iMSCP::AbstractModuleActionspostdeleteMail()

=cut

sub postdeleteMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteMail', $data );
}

=item predisableMail( \%data )

 See iMSCP::AbstractModuleActionspredisableMail()

=cut

sub predisableMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predisableMail', $data );
}

=item disableMail( \%data )

 See iMSCP::AbstractModuleActionsdisableMail()

=cut

sub disableMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'disableMail', $data );
}

=item postdisableMail( \%data )

 See iMSCP::AbstractModuleActionspostdisableMail()

=cut

sub postdisableMail
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdisableMail', $data );
}


=item preaddServerIP( \%data )

 See iMSCP::AbstractModuleActionspreaddServerIP()

=cut

sub preaddServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddServerIP', $data );
}

=item addServerIP( \%data )

 See iMSCP::AbstractModuleActionsaddServerIP()

=cut

sub addServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addServerIP', $data );
}

=item postaddServerIP( \%data )

 See iMSCP::AbstractModuleActionspostaddServerIP()

=cut

sub postaddServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddServerIP', $data );
}

=item predeleteServerIP( \%data )

 See iMSCP::AbstractModuleActionspredeleteServerIP()

=cut

sub predeleteServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteServerIP', $data );
}

=item deleteServerIP( \%data )

 See iMSCP::AbstractModuleActionsdeleteServerIP()

=cut

sub deleteServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteServerIP', $data );
}

=item postdeleteServerIP( \%data )

 See iMSCP::AbstractModuleActionspostdeleteServerIP()

=cut

sub postdeleteServerIP
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteServerIP', $data );
}

=item preaddSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionspreaddSSLcertificate()

=cut

sub preaddSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddSSLcertificate', $data );
}

=item addSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionsaddSSLcertificate()

=cut

sub addSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addSSLcertificate', $data );
}

=item postaddSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionspostaddSSLcertificate()

=cut

sub postaddSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddSSLcertificate', $data );
}

=item predeleteSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionspredeleteSSLcertificate()

=cut

sub predeleteSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteSSLcertificate', $data );
}

=item deleteSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionsdeleteSSLcertificate()

=cut

sub deleteSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteSSLcertificate', $data );
}

=item postdeleteSSLcertificate( \%data )

 See iMSCP::AbstractModuleActionspostdeleteSSLcertificate()

=cut

sub postdeleteSSLcertificate
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteSSLcertificate', $data );
}

=item preaddUser( \%data )

 See iMSCP::AbstractModuleActionspreaddUser()

=cut

sub preaddUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'preaddUser', $data );
}

=item addUser( \%data )

 See iMSCP::AbstractModuleActionsaddUser()

=cut

sub addUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'addUser', $data );
}

=item postaddUser( \%data )

 See iMSCP::AbstractModuleActionspostaddUser()

=cut

sub postaddUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postaddUser', $data );
}

=item predeleteUser( \%data )

 See iMSCP::AbstractModuleActionspredeleteUser()

=cut

sub predeleteUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'predeleteUser', $data );
}

=item deleteUser( \%data )

 See iMSCP::AbstractModuleActionsdeleteUser()

=cut

sub deleteUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'deleteUser', $data );
}

=item postdeleteUser( \%data )

 See iMSCP::AbstractModuleActionspostdeleteUser()

=cut

sub postdeleteUser
{
    my ( $self, $data ) = @_;

    $self->_executeActionOnSelectedPackages( 'postdeleteUser', $data );
}

=item getType( )

 Get type of packages for this collection

 Return string Type of packages

=cut

sub getType
{
    my ( $self ) = @_;

    die( sprintf( 'The %s package must implement the getType() method', ref $self ));
}

=item getSelectedPackages( )

 Get list of selected package instances from this collection, sorted in descending order of priority

 Return arrayref Array containing list of selected package instances

=cut

sub getSelectedPackages
{
    my ( $self ) = @_;

    @{ $self->{'SELECTED_PACKAGE_INSTANCES'} } ||= do {
        [
            sort { $b->getPriority() <=> $a->getPriority() } map {
                my $package = "Packages::@{ [ $self->getType() ] }::${_}";
                eval "require $package; 1" or die( sprintf( "Couldn't load the '%s' package: %s", $_, $@ ));
                $package->getInstance()
            } @{ $self->{'SELECTED_PACKAGES'} }
        ]
    };
}

=item getUnselectedPackages( )

 Get list of unselected package instances from this collection, sorted in descending order of priority

 Return array Array containing list of unselected package instances

=cut

sub getUnselectedPackages
{
    my ( $self ) = @_;

    $self->{'UNSELECTED_PACKAGE_INSTANCES'} ||= do {
        my @unselectedPackages;
        for my $package ( $self->{'AVAILABLE_PACKAGES'} ) {
            next if grep ( $package eq $_, @{ $self->{'SELECTED_PACKAGES'} } );
            push @unselectedPackages, $package;
        }

        [
            sort { $b->getPriority() <=> $a->getPriority() } map {
                my $package = "Packages::@{ [ $self->getType() ] }::${_}";
                eval "require $package; 1" or die( sprintf( "Couldn't load the '%s' package: %s", $_, $@ ));
                $package->getInstance();
            } @unselectedPackages
        ]
    };
}

=back

=head1 PRIVATE METHODS

=over 4

=item init( )

 See Package::Abstract::_init()

=cut

sub _init
{
    my ( $self ) = @_;

    ref $self ne __PACKAGE__ or confess( sprintf( 'The %s class is an abstract class which cannot be instantiated', __PACKAGE__ ));

    $self->SUPER::_init();
    $self->_loadAvailablePackages() if iMSCP::Getopt->context() eq 'installer';
    $self->_loadSelectedPackages();
    $self;
}

=item _askForPackages( $dialog )

 Ask for packages to install

 Param iMSCP::Dialog $dialog
 Return int 0 (NEXT), 20 (SKIP), 30 (BACK), 50 (ESC)

=cut

sub _askForPackages
{
    my ( $self, $dialog ) = @_;

    my $packageType = $self->getType();
    my $ucPackageType = uc $packageType;

    @{ $self->{'SELECTED_PACKAGES'} } = split ',', ::setupGetQuestion( $ucPackageType . '_PACKAGES' );
    my %choices = map { $_ => ucfirst $_ } @{ $self->{'AVAILABLE_PACKAGES'} };

    if ( isOneOfStringsInList( iMSCP::Getopt->reconfigure, [ lc $packageType, 'all' ] ) || !@{ $self->{'SELECTED_PACKAGES'} }
        || grep { !exists $choices{$_} && $_ ne 'none' } @{ $self->{'SELECTED_PACKAGES'} }
    ) {
        ( my $rs, $self->{'SELECTED_PACKAGES'} ) = $dialog->checklist(
            <<"EOF", \%choices, [ grep { exists $choices{$_} && $_ ne 'none' } @{ $self->{'SELECTED_PACKAGES'} } ] );

Please select the $packageType packages you want to install:
\Z \Zn
EOF
        return $rs unless $rs < 30;
    }

    @{ $self->{'SELECTED_PACKAGES'} } = grep ( $_ ne 'none', @{ $self->{'SELECTED_PACKAGES'} } );
    ::setupSetQuestion( $ucPackageType . '_PACKAGES', @{ $self->{'SELECTED_PACKAGES'} } ? join( ',', @{ $self->{'SELECTED_PACKAGES'} } ) : 'none' );

    my $dialogs = [];
    for my $package ( @{ $self->getSelectedPackages() } ) {
        my $rs = $package->registerInstallerDialogs( $dialogs );
        return $rs if $rs;
    }

    $dialog->executeDialogs( $dialogs )
}

=item _loadAvailablePackages()

 Load list of available packages for this collection

 Return void, die on failure

=cut

sub _loadAvailablePackages
{
    my ( $self ) = @_;

    s/\.pm$// for @{ $self->{'AVAILABLE_PACKAGES'} } = iMSCP::Dir->new(
        dirname => "$::imscpConfig{'ENGINE_ROOT_DIR'}/PerlLib/Package/" . $self->getType()
    )->getFiles();
}

=item _loadAvailablePackages()

 Load list of selected packages for this collection

 Return void, die on failure

=cut

sub _loadSelectedPackages
{
    my ( $self ) = @_;

    @{ $self->{'SELECTED_PACKAGES'} } = grep ( $_ ne 'none', split( ',', $::imscpConfig{ $self->getType() . '_PACKAGES' } ) );
}

=item _executeActionOnSelectedPackages( $action [, @params ] )

 Execute the given action on selected packages

 Param coderef $action Action to execute on packages
 Param List @params List of parameters to pass to the package action method
 Return int 0 on success, other on failure

=cut

sub _executeActionOnSelectedPackages
{
    my ( $self, $action, @params ) = @_;

    for my $package ( @{ $self->getSelectedPackages() } ) {
        debug( sprintf( "Executing '%s' action on %s", $action, $package ));
        my $rs = $package->$action( @params );
        return $rs if $rs;
    }

    0;
}

=back

=head1 AUTHOR

 Laurent Declercq <l.declercq@nuxwin.com>

=cut

1;
__END__