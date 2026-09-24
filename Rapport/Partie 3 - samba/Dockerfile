# ============================================================
# SAE2.04-3 - Image Samba personnalisee
# Base : ubuntu:22.04
# Objectif : serveur de partage avec 3 groupes et 6 repertoires
# Mot de passe de tous les comptes : root
# ============================================================

FROM ubuntu:22.04

# Eviter les questions interactives pendant apt-get
# (ex: fuseau horaire de tzdata)
ENV DEBIAN_FRONTEND=noninteractive

# Installation de Samba et des outils reseau utiles
RUN apt-get update && apt-get install -y \
    samba \
    smbclient \
    cifs-utils \
    net-tools \
    iputils-ping \
    expect \
    && rm -rf /var/lib/apt/lists/*

# Creation des trois groupes correspondant au cahier des charges
RUN groupadd cmoi \
 && groupadd ctoi \
 && groupadd cnous

# Creation des utilisateurs Linux et affectation a leur groupe principal
# -m : cree le repertoire personnel
# -s /bin/bash : shell par defaut
# -g : groupe principal
RUN useradd -m -s /bin/bash -g cmoi  moi \
 && useradd -m -s /bin/bash -g ctoi  toi \
 && useradd -m -s /bin/bash -g cnous nous

# Creation des six repertoires de partage
RUN mkdir -p /partage/amoi \
             /partage/atoi \
             /partage/anous \
             /partage/public \
             /partage/amoi-atoi \
             /partage/amoi-anous

# Application des droits Linux selon le cahier des charges :
#   chmod 2770 (rwxrws---) : acces restreint au groupe, setgid pour heritage
#   chmod 1777 (rwxrwxrwt) : public accessible par tous, sticky bit
#   chmod 2775 (rwxrwsr-x) : partage groupe + lecture publique, setgid
RUN chown -R root:cmoi   /partage/amoi \
 && chown -R root:ctoi   /partage/atoi \
 && chown -R root:cnous  /partage/anous \
 && chown -R root:cmoi   /partage/amoi-atoi \
 && chown -R root:cmoi   /partage/amoi-anous \
 && chmod -R 2770 /partage/amoi /partage/atoi /partage/anous \
 && chmod    1777 /partage/public \
 && chmod -R 2775 /partage/amoi-atoi /partage/amoi-anous

# Copie de la configuration Samba (6 partages avec droits detailles)
COPY smb.conf /etc/samba/smb.conf

# Copie du script de demarrage (creation comptes Samba + lancement services)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ports utilises par Samba :
#   137/udp, 138/udp : NetBIOS (nmbd)
#   139, 445         : SMB/CIFS (smbd)
EXPOSE 137/udp 138/udp 139 445

ENTRYPOINT ["/entrypoint.sh"]
