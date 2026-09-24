#!/bin/bash
# ============================================================
# entrypoint.sh - Script de demarrage du conteneur Samba
#
# Les comptes Samba ne peuvent pas etre crees pendant le build
# (la base tdb de Samba n'est pas active a ce moment).
# Ce script les initialise au demarrage du conteneur.
# Mot de passe : root pour tous les utilisateurs
# ============================================================

# Ajout de chaque utilisateur Linux dans la base Samba
# smbpasswd -a : ajoute l'utilisateur
# smbpasswd -e : active le compte (desactive par defaut apres ajout)
for user in moi toi nous; do
  echo -e 'root\nroot' | smbpasswd -a $user
  smbpasswd -e $user
done

# Demarrage de nmbd (resolution NetBIOS) en mode daemon
nmbd -D

# Demarrage de smbd (partage de fichiers SMB) en mode daemon
smbd -D

# Maintenir le conteneur actif en suivant les logs Samba
tail -f /var/log/samba/log.smbd
