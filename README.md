Projet intégratif S2

> **BUT Réseaux & Télécommunications — Semestre 2**
> IUT de Roanne — Département R&T
> Auteur : **Nathanaël Berthod**

Ce dépôt regroupe les livrables (rapports, configurations, scripts et médias) de la **SAÉ 2.04 — Projet intégratif du semestre 2**. Le projet est découpé en quatre parties indépendantes qui mobilisent chacune un pan différent du programme R&T : développement web, mathématiques, administration systèmes/réseaux et téléphonie sur IP.

---

## Sommaire

- [Structure du dépôt](#structure-du-dépôt)
- [Partie 1 — Site web](#partie-1--site-web)
- [Partie 2 — Art mathématique](#partie-2--art-mathématique)
- [Partie 3 — Samba (partage de fichiers)](#partie-3--samba-partage-de-fichiers)
- [Partie 4 — Asterisk (téléphonie IP)](#partie-4--asterisk-téléphonie-ip)
- [Prérequis techniques](#prérequis-techniques)
- [Auteur](#auteur)
- [Licence](#licence)

---

## Structure du dépôt

```
Rapport/
├── Partie 1 - site web/
│   ├── Compte_rendu_SAE24_BERTHOD.docx
│   └── Diaporama_SAE24_BERTHOD.pptx
│
├── Partie 2 - Art mathematique/
│   └── compte_rendu_SAE204.docx
│
├── Partie 3 - samba/
│   ├── Compte_Rendu_SAE204_Samba.docx
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── entrypoint.sh
│   ├── smb.conf
│   └── README.txt
│
└── Partie 4 - Asterisk/
    ├── SAÉ 2.04 (Partie 4).docx
    ├── custom/                  # annonces .wav pour l'IVR
    │   ├── annonce-horaires.wav
    │   ├── annonce-vacances.wav
    │   ├── ivr-menu.wav
    │   ├── ivr-invalide.wav
    │   └── numero-inconnu.wav
    └── etc/                     # fichiers de configuration Asterisk
        ├── extensions.conf
        ├── pjsip.conf
        ├── rtp.conf
        └── voicemail.conf
```

---

## Partie 1 — Site web

Réalisation d'un site web statique / dynamique dans le cadre de la SAÉ. Le dossier contient :

- 📄 **Compte_rendu_SAE24_BERTHOD.docx** — rapport détaillé de la démarche (maquettage, structure HTML/CSS, tests).
- 📊 **Diaporama_SAE24_BERTHOD.pptx** — support de présentation orale.

> ℹ️ Consulter le compte-rendu pour la description complète des choix techniques (framework, hébergement, accessibilité).

---

## Partie 2 — Art mathématique

Étude d'une figure ou d'une œuvre générée à partir de propriétés mathématiques (courbes, fractales, symétries…).

- 📄 **compte_rendu_SAE204.docx** — présentation du sujet, démonstrations, illustrations et interprétation artistique.

---

## Partie 3 — Samba (partage de fichiers)

Mise en place d'une **infrastructure de partage Samba sous Docker** avec trois approches complémentaires. Trois groupes (`cmoi`, `ctoi`, `cnous`) et six partages avec droits fins :

| Répertoire   | cmoi | ctoi | cnous | Description                       |
|--------------|:----:|:----:|:-----:|-----------------------------------|
| `amoi`       | R+W  |  —   |   —   | Privé de cmoi                     |
| `atoi`       |  R   | R+W  |   —   | Privé de ctoi                     |
| `anous`      |  R   |  R   |  R+W  | Privé de cnous                    |
| `public`     | R+W  | R+W  |  R+W  | Accessible par tous               |
| `amoi-atoi`  | R+W  |  R   |   —   | Partage cmoi/ctoi (géré par cmoi) |
| `amoi-anous` | R+W  |  —   |   R   | Partage cmoi/cnous (géré par cmoi)|

**Mot de passe par défaut de tous les comptes :** `root`

### Prérequis réseau

```bash
docker network create --driver bridge --subnet 172.20.0.0/24 --gateway 172.20.0.1 samba
```

### Approche 1 — `dperson/samba` en une commande

```bash
docker run -it -d \
  --name samba-dperson \
  --privileged --hostname samba-dperson \
  --network samba --ip 172.20.0.30 \
  dperson/samba -p -S -n -w "WORKGROUP" \
    -u "moi;root" -u "toi;root" -u "nous;root" \
    -s "public;/mount/public;yes;no;yes;moi,toi,nous" \
    -s "amoi;/mount/amoi;no;no;no;moi" \
    -s "atoi;/mount/atoi;no;no;no;toi" \
    -s "anous;/mount/anous;no;no;no;nous" \
    -s "amoi-atoi;/mount/amoi-atoi;no;no;no;moi,toi" \
    -s "amoi-anous;/mount/amoi-anous;no;no;no;moi,nous"
```

### Approche 2 — Dockerfile personnalisé (contrôle total des droits)

```bash
cd "Partie 3 - samba/"
docker build -t samba-sae204 .
docker run -d --privileged --name samba-custom \
  --network samba --ip 172.20.0.40 samba-sae204
```

L'image se base sur `ubuntu:22.04` et applique les droits Linux exacts (`chmod 2770/1777/2775`, `setgid`, `sticky bit`) via `smb.conf` et `entrypoint.sh`.

### Approche 3 — Docker Compose

```bash
cd "Partie 3 - samba/"
docker compose up -d
docker compose ps
docker compose down
```

### Tests rapides

```bash
docker exec samba-custom smbclient -L //172.20.0.40 -U moi%root
docker exec samba-custom smbclient //172.20.0.40/amoi -U moi%root -c "mkdir test; ls"
```

Documentation détaillée dans [Partie 3 - samba/README.txt](Partie%203%20-%20samba/README.txt) et le compte-rendu associé.

---

## Partie 4 — Asterisk (téléphonie IP)

Déploiement d'un **PABX Asterisk** simulant l'atelier téléphonique d'un collectif d'artistes, hébergé sur une VM **Google Cloud** (NAT 1:1, IP publique `34.62.55.225`).

### Fonctionnalités mises en place

- 🎨 **4 postes SIP** (extensions 200 → 203) avec `callerid` et messagerie vocale :
  - `200` Léon Ardavinci
  - `201` Paul Picasso
  - `202` Mickael Angelo
  - `203` Salvatore Dalida
- ☎️ **Compte opérateur** simulant le RTC (réseau téléphonique commuté).
- 🕒 **Contrôle horaire** — atelier ouvert 8h→18h, 7j/7, du 01/09 au 11/06. Congés en juillet-août et 12→30 juin.
- 📞 **Sélection Directe à l'Arrivée (SDA)** — `0477777777` → Léon, `0488888888` → Mickael.
- 🎙️ **Serveur Vocal Interactif** (`0466666666`) avec menu :
  - `0` → Léon, `1` → Paul, `2` → Mickael, `3` → Salvatore
- 📬 **Messagerie vocale** consultable via `*97`.
- 🔁 **Fallback** vers messagerie si occupé/pas de réponse (variable `DUREE_SONNERIE=20`).
- 🧪 **Mode démo** — `dialplan set global FORCE_OUVERT 1` force l'ouverture pour tester à toute heure.

### Fichiers de configuration

| Fichier                        | Rôle                                                                 |
|--------------------------------|----------------------------------------------------------------------|
| [`etc/pjsip.conf`](Partie%204%20-%20Asterisk/etc/pjsip.conf)         | Transport UDP:5060, endpoints PJSIP des 4 artistes + opérateur       |
| [`etc/extensions.conf`](Partie%204%20-%20Asterisk/etc/extensions.conf) | Plan de numérotation (contextes `internal`, `from-pstn`, `ivr`, sous-programmes) |
| [`etc/voicemail.conf`](Partie%204%20-%20Asterisk/etc/voicemail.conf)   | Boîtes vocales des postes 200-203                                   |
| [`etc/rtp.conf`](Partie%204%20-%20Asterisk/etc/rtp.conf)               | Plage de ports RTP                                                  |
| `custom/*.wav`                 | Annonces vocales (accueil IVR, horaires, vacances, numéro inconnu)   |

### Déploiement

Copier les fichiers dans `/etc/asterisk/` et les `.wav` dans `/var/lib/asterisk/sounds/custom/`, puis :

```bash
sudo asterisk -rvvv          # console de supervision
> pjsip reload
> dialplan reload
> voicemail reload
> pjsip show endpoints
```

### Client SIP recommandé

Softphone **Linphone** (desktop ou mobile) — s'enregistrer sur `34.62.55.225` avec l'un des comptes `200-203` (mot de passe `Atelier<num>`).

---

## Prérequis techniques

| Partie   | Outils / technologies                                       |
|----------|-------------------------------------------------------------|
| Partie 1 | HTML5, CSS3, éditeur au choix                              |
| Partie 2 | Traitement de texte, éventuellement outil de tracé mathématique |
| Partie 3 | Docker 20.10+, Docker Compose v2, `smbclient`, `cifs-utils` |
| Partie 4 | Asterisk 18+, PJSIP, VM Linux (Debian/Ubuntu), softphone Linphone |

---

## Auteur

**Nathanaël Berthod** — Étudiant BUT R&T, IUT de Roanne
