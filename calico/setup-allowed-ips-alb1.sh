#!/bin/bash
#######################################################################################################################
AGENT_OS=`uname`                                                                                                      #
KUBECTL=`which kubectl`                                                                                               #
LOGDATE=`date +%F%t%T | sed 's/:/-/g' | awk '{print $1"-"$2}'`                                                        #
YAMLTEMPLATE="allow-ips-alb1-template.yml"                                                                            #
OUTPUTYAML="allow-ips-alb1.yml"                                                                                        #
ALBIPFILE="alb1-source-ips.txt"                                                                                       #                                                
#######################################################################################################################

function GetAlb1Template {
if [ -f $YAMLTEMPLATE ]; then
   echo "Success: The YAML template allow-ips-alb1-template.yml exists" 
   cp -f $YAMLTEMPLATE $OUTPUTYAML
   if [ $? != "0" ]; then
      echo "ERROR : Failed to create $OUTPUTYAML" 
      exit 1
  fi
  else
   echo "ERROR : The YAML template allow-ips-alb1-template.yml DOES NOT exist" 
 exit 1
fi
}

function GetProperties {
if [ -f $ALBIPFILE ]; then
   echo "Success: alb1-source-ips.txt exists" 
  else
   echo "ERROR : The environment file alb1-source-ips.txt DOES NOT exist" 
 exit 1
fi
}

function SedALBYAML {
  sed -i "s~NLB_OR_ALB_IP_CIDR~$ALBIPCIDR~g" $OUTPUTYAML
  if [ $? != "0" ]; then
      echo "ERROR : Failed to create to update YAML" 
      exit 1
  fi
}

function SedYAML {
  sed -i "s~$IPVARNUM~$IPCIDR~g" $OUTPUTYAML
  if [ $? != "0" ]; then
      echo "ERROR : Failed to create to update YAML" 
      exit 1
  fi
}

#############################################################################
GetAlb1Template
GetProperties 

while read IPLINE ; 
do (
    echo "Checking for ALB"
    ALBIP=`echo $IPLINE | grep 'NLB_OR_ALB_IP_CIDR'`
    if [ -z $ALBIP ]; then 
      echo "$ALBIP is not an ALB"
      else
      echo "Checking property" $ALBIP
      ALBIPCIDR=`echo $IPLINE | awk -F '=' '{print $2}' | egrep "[0-9].*/[0-9][0-9]"`
      if [ -z $ALBIPCIDR ]; then 
       echo "Invalid ALB CIDR block"
       else
         echo "Updating ALB CIDR"
         echo "Update with" $ALBIPCIDR
        SedALBYAML
      fi
    fi
) ; done <  $ALBIPFILE

while read IPVAR ; 
do (
    echo "Checking property" $IPVAR 
    IPVARNUM=`echo $IPVAR| awk -F '=' '{print $1}'`
    IPCIDR=`echo $IPVAR| awk -F '=' '{print $2}' | egrep "[0-9].*/[0-9][0-9]"`
    if [ -z $IPCIDR ]; then 
    echo "Invalid CIDR block"
    else
    echo "Updating an allowed IP block"
     echo "The YAML var" $IPVARNUM
    echo "Update with" $IPCIDR
    SedYAML
    fi
); done < $ALBIPFILE

echo "############################### YAML ##############################################"
cat $OUTPUTYAML
echo "###################################################################################"
