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
sfdx sgd:source:delta --to $SourceBranchCommit --from $TargetBranchCommit --output . -a 61.0 --ignore .forceignore

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

# Check if package/package.xml exists
if [ -f "package/package.xml" ]; then
  # Check if WorkflowAlert is present in package/package.xml
  workflowExist=$(grep -E "<name>WorkflowAlert</name>|<name>WorkflowFieldUpdate</name>|<name>WorkflowOutboundMessage</name>|<name>WorkflowRule</name>" package/package.xml)
  if [ ! -z "$workflowExist" ]; then
    # Get the line number for <version>60.0</version>
    LINE_NUM=$(grep -n "<version>60.0</version>" package/package.xml | cut -d: -f1)
    if [ -n $LINE_NUM ]; then
      # Define the XML block to insert
      XML_BLOCK="<types>
  <members>Lead</members>
  <members>CustomerInformationFormStaging__c</members>
  <name>Workflow</name>
</types>"
      # Insert the block above the version line
      awk -v xml="$XML_BLOCK" -v line=$LINE_NUM 'NR==line {print xml} {print}' package/package.xml > temp.xml && mv temp.xml package/package.xml
    fi
  fi
fi

# Display the updated package.xml content
cat package/package.xml

