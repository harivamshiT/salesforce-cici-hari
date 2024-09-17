#!/bin/bash
if [ $# -eq 2 ];
then
    SourceBranchCommit=$1
    TargetBranchCommit=$2
else 
    echo "******ERROR****** Please provide proper input in argument"
    exit 1;
fi
npm install @salesforce/cli --global
pip install xq
pip install yq
echo y | sf plugins install sfdx-git-delta;
sfdx sgd:source:delta --to $SourceBranchCommit --from $TargetBranchCommit --output . -a 55 --ignore .forceignore

echo "existing destructiveChanges file  . .. .  "
cat destructiveChanges/destructiveChanges.xml

if [ -f "destructiveChanges/destructiveChanges.xml" ];
then
    flowDestructiveExistance=$(grep -c "<name>Flow</name>" destructiveChanges/destructiveChanges.xml)
    if [ -n "$flowDestructiveExistance" ] && [ $flowDestructiveExistance -ge 1 ];
    then
        cp -v destructiveChanges/destructiveChanges.xml package/destructiveChanges.xml
        echo "***************** As Flow has been deleted and we can't delete flow using metadata API, please delete destructive changes manually . . . Please follow - https://gearset.com/blog/flows-and-flow-definitions/ for reference . . . ****************************"
    else
        vlxExistance=$(grep -c "vlx__" destructiveChanges/destructiveChanges.xml)
        defaultPathExistance=$(grep -c "<members>Default</members>" destructiveChanges/destructiveChanges.xml)
        if [ -n "$vlxExistance" ] && [ $vlxExistance -ge 1 ];
        then
            cp -v destructiveChanges/destructiveChanges.xml package/destructiveChanges.xml
        elif [ -n "$defaultPathExistance" ] && [ $defaultPathExistance -ge 1 ];
        then
            cp -v destructiveChanges/destructiveChanges.xml package/destructiveChanges.xml
        else
            cp -v destructiveChanges/destructiveChanges.xml package/destructiveChanges.xml
        fi
    fi
fi
cat package/package.xml

