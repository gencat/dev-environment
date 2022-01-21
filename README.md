# Entorn de desenvolupament del framework Canigó

Informació a <https://canigo.ctti.gencat.cat/canigo/entorn-desenvolupament/>

## Software base

> El software base s’ha instal·lat un conjunt de programari per a les tasques complementàries de desenvolupament. Aquest software addicional s’ha instal·lat dins el directori /opt

1. Open JDK 8
1. Open JDK 11
1. Visual VM
1. Clients per diferents BBDD (Mysql, PostgreSQL, MongoDB i Redis)
1. Navegador Mozilla FireFox Quantum
1. Client VPNC per accés a XCAT
1. Navegador Google Chrome
1. Engine Docker i Docker Compose Tool per l’execució de contenidors Docker
1. Servidor Apache HTTP (2.4)

## Software addicional

> A banda del software base s’ha instal·lat i configurat un conjunt de programari addicional dins el directori /opt, amb les versions alineades al full de ruta del programari.

1. LanguageTool 5.3 - Per revisar gramàtica, ortografia i formes correctes del català.
1. DBeaver 6.0.2 - Eina multi-paradigma (SQL, No-SQL, etc.) per a BBDD.
1. SoapUI 5.7.0 - Eina per treballar amb serveis SOAP i REST.
1. jMeter 5.1.1 - Eina per fer validacions funcionals, proves de càrrega i mesures de rendiment d’aplicacions.
1. NodeJS - Servidor d’aplicacions JS. Les versions instal·lades són 14.18.3 i 16.13.2.
1. Visual Studio Code - Editor altament extensible (mitjançant plugins). Recomanable principalment per a treballar amb tecnologies frontend (AngularJS, Javascript, Typescript, etc.)
1. Maven 3.8.3
1. Tomcat 9.0.55
1. jEdit 5.5.0 - Editor de textos (més lleuger que VS Code) basat en Java. Recomanable per a l’edició de fitxers grans (logs).
1. IDE - Spring Tool Suite 4.13.0, i els següents plugins:
   * Plugin CTTI Canigó per creació aplicacions Canigó 3.4 basades en arquitectura REST+HTML5/JS.
   * Spring Tool Suite per facilitar el desenvolupament d’aplicacions basades en Spring.
   * SonarLint permet detectar i solucionar problemes de qualitat al codi SonarLint.
