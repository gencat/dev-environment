# Entorn de desenvolupament framework JEE Canigó corporatiu de la Generalitat de Catalunya

## Objectius

* Facilitar la posada en marxa de l'entorn de desenvolupament, aprovisionant una màquina virtual amb tot el necessari per a començar el desenvolupament d'una aplicació Canigó.
* Simular els entorns de desplegament als CPD Generalitat, facilitant contenidors amb les mateixes versions i configuracions dels PaaS que ens trobarem als clouds.

## Pre requisits

* [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](http://www.vagrantup.com/downloads.html)
* [Vagranfile](https://github.com/cs-canigo/dev-environment/releases/tag/v1.0.2) amb la configuració de l'entorn Canigó 

## Com començar?

* Descarregar i descomprimir el [zip](https://github.com/cs-canigo/dev-environment/archive/v1.0.2.zip) a la carpeta que desitgem (p.e. c:/vms o /home/user/vms)

* Anar per línia de comanda a la carpeta on estigui el Vagrantfile i executem:

		vagrant up	

	Amb aquesta instrucció, vagrant aixecarà una màquina virtual a Virtualbox i executarà les comandes que inclogui el Vagrantfile. El temps d'instal·lació serà llarg degut a que instal·la tot el software necessari per a desenvolupar i desplegar en els entorns de proves (es pot veure què instal·la reseguint el shell script).

* En el moment que a la màquina virtual aixecada es vegi l'escriptori, el procés ja haurà finalitzat. Podem tancar la màquina i engegar-la i aturar-la a través de VirtualBox.


## Setup inicial

* Usuari i password: canigo/canigo

* Activar IBUS: Menú inici > Preferències > IBUS Preferences > Start ("Yes")
* Configurar el teclat per català
	
	- Menú inici > Preferències > IBUS Preferences -> Input Method -> Add ("Catalan; Valencian")
	- Menú inici > Preferències > IBUS Preferences -> Input Method -> Eliminar "English" i seleccionar ""Catalan; Valencian"

* Obrir un terminal i executar

		sudo dpkg-reconfigure keyboard-configuration

## Programari instal·lat

* IDE: [Spring Tool Suite] (https://spring.io/tools) (basat en Eclipse Mars) amb jre7 (Oracle) i els següents plugins:

	- M2Eclipse per integració amb [Apache Maven](https://maven.apache.org/)
	- CTTI Canigó per creació aplicacions Canigó 3.1 basades en arquitectura REST+HTML5/JS o JSF
	- Spring Tool Suite per facilitar el desenvolupament d'aplicacions basades en [Spring](http://spring.io/projects)
	- Subclipse per integració amb [Subversion] (https://subversion.apache.org/)
	- SonarQube per integració amb [SonarQube] (http://spring.io/projects) (antic Sonar)

* Altres

	- Engine Docker i Docker Compose Tool per l'execució de contenidors Docker
	- Navegador Google Chrome
	- Client VPNC per accés a XCAT

## Versió 2.0.0 (En construcció)

```diff
- En construcció
```

Canvis:

- Vagrant 1.9.1 x64
- Ubuntu Xenial x64
- Oracle Java 8
- STS 3.8.3
- Subclipse 4.2.2
- Docker-compose 1.9.1

Si al executar el "vagrant up" dona el següent error:

```
"VirtualBox is complaining that the kernel module is not loaded. Please
run `VBoxManage --version` or open the VirtualBox GUI to see the error
message which should contain instructions on how to fix this error."
```

Cal executar aquesta comanda:

``
sudo /etc/init.d/vboxdrv setup
``
 