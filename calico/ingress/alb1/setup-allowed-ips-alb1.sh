#!/bin/bash
#######################################################################################################################
AGENT_OS=`uname`                                                                                                      #
KUBECTL=`which kubectl`                                                                                               #
LOGDATE=`date +%F%t%T | sed 's/:/-/g' | awk '{print $1"-"$2}'`                                                        #
YAMLTEMPLATE="allow-ips-alb1-template.yml"                                                                            # 
ALBDENYFILETEMP="deny-alb1-template.yml"                                                                              #
OUTPUTYAML="allow-ips-alb1.yml"                                                                                       #
ALBIPFILE="alb1-source-ips.txt"                                                                                       #
ALBDENYFILE="deny-alb1.yml"                                                                                           #                                                
#######################################################################################################################

function Usage {
  echo "##########################################################"
  echo "#     Script to add White list for ALB1 in IKS           #"
  echo "#                Usage below:                            #" 
  echo "#   cp YAML_TEMPLATE allow-ips-alb1-template.yml         #"
  echo "#        cp IPS_TEMPLATE alb1-source-ips.txt             #"
  echo "#        cp ALBDENYFILETEMP deny-alb1-template.yml       #"
  echo "#         bash setup-allowed-ips-alb1.sh                 #"
  echo "#########################################################"
}

function GetAlb1Template {
if [ -f $YAMLTEMPLATE ]; then
   echo "Success: The YAML template allow-ips-alb1-template.yml exists" 
   cp -f $YAMLTEMPLATE $OUTPUTYAML
   if [ $? != "0" ]; then
      echo "ERROR : Failed to create $OUTPUTYAML" 
      echo "Please create a allow-ips-alb1-template.yml in" $PWD
      Usage
      exit 1
  fi
  else
   echo "ERROR : The YAML template allow-ips-alb1-template.yml DOES NOT exist"
 Usage  
 exit 1
fi
}

function GetAlb1DenyTemplate {
if [ -f $ALBDENYFILETEMP ]; then
   echo "Success: The YAML templated eny-alb1-template.yml exists" 
   cp -f $ALBDENYFILETEMP $ALBDENYFILE
   if [ $? != "0" ]; then
      echo "ERROR : Failed to create $ALBDENYFILE" 
      echo "Please create a deny-alb1-template.yml in" $PWD
      Usage
      exit 1
  fi
  else
   echo "ERROR : The YAML template deny-alb1-template.yml DOES NOT exist" 
 Usage  
 exit 1
fi
}

function GetProperties {
if [ -f $ALBIPFILE ]; then
   echo "Success: alb1-source-ips.txt exists" 
  else
   echo "ERROR : The environment file alb1-source-ips.txt DOES NOT exist" 
 Usage  
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

function SedDenyYAML {
  sed -i "s~NLB_OR_ALB_IP_CIDR~$ALBIPCIDR~g" $ALBDENYFILE
  if [ $? != "0" ]; then
      echo "ERROR : Failed to create to update YAML" 
      exit 1
  fi
}

#############################################################################
GetAlb1Template

GetProperties 

GetAlb1DenyTemplate 

while read DENYIPLINE ; 
do (
    echo "Checking for ALB"
    ALBIP=`echo $DENYIPLINE | grep 'NLB_OR_ALB_IP_CIDR'`
    if [ -z $ALBIP ]; then 
      echo "$ALBIP is not an ALB"
      else
      echo "Checking property" $ALBIP
      ALBIPCIDR=`echo $DENYIPLINE | awk -F '=' '{print $2}' | egrep "[0-9].*/[0-9][0-9]"`
      if [ -z $ALBIPCIDR ]; then 
       echo "Invalid ALB CIDR block"
       else
         echo "Updating ALB CIDR"
         echo "Update with" $ALBIPCIDR
        SedDenyYAML
      fi
    fi
) ; done <  $ALBIPFILE
 

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
printf "\n"
cat $ALBDENYFILE
printf "\n"
echo "###################################################################################"