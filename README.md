# Einführung in das ABAP-RESTful-Programmiermodell

Hier finden Sie den Code für die Veranstaltung [_ABAP RESTful Application Programming Model_](https://www.rheinwerk-verlag.de/online-kurse/rap-fullstack-entwicklung-fuer-sap/) des Rheinwerk-Verlags.

## Voraussetzungen
Um den Code auf Ihrem ABAP-System zu installieren, benötigen Sie [Eclipse mit ADT](https://developers.sap.com/tutorials/abap-install-adt.html) und das [abapGit Plugin für Eclipse](https://developers.sap.com/tutorials/abap-install-abapgit-plugin.html).

Der Code in diesem Repository basiert auf dem [ABAP Flight Reference Scenario for RAP on ABAP Platform Cloud](https://github.com/SAP-samples/abap-platform-refscen-flight/tree/ABAP-platform-cloud).

## Download
Verwenden Sie das abapGit Plugin und führen Sie folgende Schritte aus:
1. Legen Sie das ABAP-Paket `Z000_RAP` (mit dem übergeordneten Paket `ZLOCAL`) in Ihrem ABAP-Clouddprojekt an.
2. Klicken Sie in der Menüleiste auf `Window` > `Show View` > `Other...` und wählen die View `abapGit Repositories` aus.
3. Klicken Sie in der View <em>abapGit Repositories</em> das Icon `+`, um ein abapGit repository zu Klonen.
4. Geben Sie die URL dieses Repositories ein: `https://github.com/MichaelWegelin/RAP.git` und wählen Sie <em>Next</em> aus.
5. Wählen Sie den Zweig <em>main</em> and geben Sie ihr soeben erzeugtes Paket `Z000_RAP` als Zielpaket an und wählen dann <em>Next</em>.
6. Legen Sie einen neuen Transportauftrag an, den Sie nur für die Installation dieses Repositories verwenden und wählen Sie <em>Finish</em>, um das Git-Repository mit Ihrem ABAP-Cloudprojekt zu verknüpfen. Das Repository erschein in der View `abapGit Repositories` mit dem Status <em>Linked</em>.
7. Rechtsklicken Sie auf das neue ABAP-Repository und wählen `pull`, um den Inhalt des Repository zu klonen. Dies kann einige Minuten dauern. 
8. Sobald das Klonen abgeschlossen ist, wird der Status auf `Pulled Successfully` gesetzt. 

