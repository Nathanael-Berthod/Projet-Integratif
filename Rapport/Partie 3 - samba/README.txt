================================================================================
SAE2.04-3 - Infrastructure de partage avec Samba4 sous Docker
IUT de Roanne - Departement Reseaux et Telecommunications
================================================================================

CAHIER DES CHARGES
------------------
Trois groupes : cmoi (user: moi), ctoi (user: toi), cnous (user: nous)
Mot de passe de tous les comptes : root

  Repertoire  | cmoi  | ctoi  | cnous | Description
  ------------|-------|-------|-------|---------------------------
  amoi        | R+W   |  --   |  --   | Prive de cmoi
  atoi        | R     | R+W   |  --   | Prive de ctoi
  anous       | R     | R     | R+W   | Prive de cnous
  public      | R+W   | R+W   | R+W   | Accessible par tous
  amoi-atoi   | R+W   | R     |  --   | Partage cmoi/ctoi, cmoi gere
  amoi-anous  | R+W   |  --   | R     | Partage cmoi/cnous, cmoi gere

================================================================================
APPROCHE 1 - Commande Docker unique avec dperson/samba (hub Docker)
================================================================================

Cette approche utilise l'image dperson/samba disponible sur Docker Hub.
Elle configure tout en une seule commande via des arguments -u (users) et -s (shares).

PREREQUIS : creer le reseau Docker
  docker network create --driver bridge --subnet 172.20.0.0/24 --gateway 172.20.0.1 samba

COMMANDE :

docker run -it -d \
  --name samba-dperson \
  --privileged \
  --hostname samba-dperson \
  --network samba \
  --ip 172.20.0.30 \
  dperson/samba -p \
    -S -n -w "WORKGROUP" \
    -u "moi;root" \
    -u "toi;root" \
    -u "nous;root" \
    -s "public;/mount/public;yes;no;yes;moi,toi,nous" \
    -s "amoi;/mount/amoi;no;no;no;moi" \
    -s "atoi;/mount/atoi;no;no;no;toi" \
    -s "anous;/mount/anous;no;no;no;nous" \
    -s "amoi-atoi;/mount/amoi-atoi;no;no;no;moi,toi" \
    -s "amoi-anous;/mount/amoi-anous;no;no;no;moi,nous"

Format du parametre -s : nom;chemin;browsable;readonly;guest;utilisateurs

NOTE : avec dperson/samba, la gestion des droits est par acces (qui peut
se connecter). Le controle fin lecture/ecriture par utilisateur necessite
l'approche Dockerfile (voir APPROCHE 2).

TEST :
  docker exec samba-dperson smbclient -L //172.20.0.30 -U moi%root
  docker exec samba-dperson smbclient //172.20.0.30/amoi -U moi%root -c "ls"

ARRETER :
  docker stop samba-dperson && docker rm samba-dperson

================================================================================
APPROCHE 2 - Dockerfile personnalise (controle total des droits)
================================================================================

Cette approche construit une image sur mesure avec les droits Linux exacts
correspondant au cahier des charges.

Fichiers necessaires (dans le meme repertoire) :
  - Dockerfile      : construction de l'image
  - smb.conf        : configuration Samba avec les 6 partages
  - entrypoint.sh   : initialisation des comptes Samba au demarrage

CONSTRUIRE ET LANCER :
  docker build -t samba-sae204 .
  docker run -d --privileged --name samba-custom --network samba --ip 172.20.0.40 samba-sae204

TEST :
  docker exec samba-custom smbclient -L //172.20.0.40 -U moi%root
  docker exec samba-custom smbclient //172.20.0.40/amoi -U moi%root -c "mkdir test; ls"

================================================================================
APPROCHE 3 - Docker Compose
================================================================================

  docker compose up -d
  docker compose ps
  docker compose down

================================================================================
