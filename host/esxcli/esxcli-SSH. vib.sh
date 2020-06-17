#To install or update a .zip file, use the -d option. To install or update a .vib file use the -v option.

esxcli software vib install -[d/v] "/vmfs/volumes/Datastore/DirectoryName/PatchName.zip" 

esxcli software vib update -d "/vmfs/volumes/Datastore/DirectoryName/PatchName.zip" 

esxcli software vib list | grep nmst
esxcli software vib list | grep mft
