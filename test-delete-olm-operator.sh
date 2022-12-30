#!/bin/bash
#######################################################################################################################
AGENT_OS=`uname`                                                                                                      #
KUBECTL=`which kubectl`                                                                                               #
LOGDATE=`date +%F%t%T | sed 's/:/-/g' | awk '{print $1"-"$2}'`                                                        #
DELETELOG="delete-olm-${LOGDATE}.log"                                                                                 #
OUTPUTDIR="delete-olm-output-${LOGDATE}"                                                                              #
BACKUPDIR=$1                                                                                                          #
#######################################################################################################################

function GetOLMOperator {
${KUBECTL} get deploy olm-operator -n ibm-system  -o=yaml  > ${OUTPUTDIR}/olm-operator-deployment.yml  2>> ${DELETELOG} 

if [ $? != "0" ]; then
 echo "ERROR : Failed to get OLM Deployment in Namespace ibm-system" 
  exit 1
 else
 echo "INFO : ibm-system ns exists with OLM Deployment"
fi
}


function GetOLMDeployedAddons {
echo "INFO : Checking if Addons were installed via OLM on ${CLUSTERID} in NS ibm-system"
${KUBECTL} get clusterserviceversions.operators.coreos.com -A > ${OUTPUTDIR}/${CLUSTERID}addons-olm-managed.txt 2>&1 

if [ -f ${OUTPUTDIR}/${CLUSTERID}addons-olm-managed.txt ]; then
   echo "DEBUG : ${OUTPUTDIR}/${CLUSTERID}addons-olm-managed.txt exists" >> ${DELETELOG} 2>&1 
  else
   echo "ERROR : ${OUTPUTDIR}/${CLUSTERID}addons-olm-managed.txt DOES NOT EXIST !" 
 exit 1
fi

KSOLMCOUNT=`egrep -v 'No resources found' ${OUTPUTDIR}/${CLUSTERID}addons-olm-managed.txt  | wc -l`
if [ ${KSOLMCOUNT} != "0" ]; then
 echo "ERROR : Cluster addons installed via OLM on${CLUSTERID} in NS ibm-system"
 exit 1
 else 
 echo "INFO: Cluster addons NOT installed via OLM on ${CLUSTERID} in NS ibm-system"
fi
}

function GetOLMAddons {
# Check for Rancher local dev
if [ ${K8SENV} != "Rancher" ]; then
echo "DEBUG : Running - 'grep -A 1  Name ${OUTPUTDIR}/${CLUSTERID}-addons.txt| egrep '^Name.*' |  wc -l' >> ${DELETELOG} 2>&1" 
ibmcloud ks cluster addons -c ${CLUSTERID} > ${OUTPUTDIR}/${CLUSTERID}-addons.txt
if [ -f ${OUTPUTDIR}/${CLUSTERID}-addons.txt ]; then
   echo "DEBUG : ${OUTPUTDIR}/${CLUSTERID}-addons.txt exists" >> ${DELETELOG} 2>&1 
  else
   echo "ERROR : ${OUTPUTDIR}/${CLUSTERID}-addons.txt DOES NOT EXIST !" 
 exit 1
fi
KSCOUNT=`grep -A 1  Name ${OUTPUTDIR}/${CLUSTERID}-addons.txt| egrep '^Name.*' |  wc -l`
 else
KSCOUNT="0"
fi 

if [ ${KSCOUNT} != '0' ]; then
 echo "WARN : Cluster addons in use in ${CLUSTERID} in NS ibm-system"
 GetOLMDeployedAddons
  else 
 echo "INFO : Cluster addons NOT in use in ${CLUSTERID} in NS ibm-system"
fi
}

function OutputCRDdetails {
 CNTCATALOGSRC=`cat ${BACKUPDIR}/catalogsources-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTCATALOGSRC} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
 
 CNTSRVCVER=`cat ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTSRVCVER} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
 
 CNTINSTALLPLN=`cat ${BACKUPDIR}/installplans-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTINSTALLPLN} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
 
 CNTOPERGRP=`cat ${BACKUPDIR}/operatorgroups-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTOPERGRP} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
 
 CNTOPROPR=`cat ${BACKUPDIR}/operators-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTOPROPR} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
 
 CNTSUBSR=`cat ${BACKUPDIR}/subscriptions-operators-coreos-com.txt | egrep "No resources found." | wc -l`
 if [ ${CNTSUBSR} != '0' ]; then
 echo "WARN : CRD catalogsources.operators.coreos.com IN USE"
  else 
 echo "INFO : CRD catalogsources.operators.coreos.com not in use"
 fi
}

function TestDeleteOLM {
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/aggregate-olm-edit.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/aggregate-olm-edit.yml"
  else
   echo "ERROR : backup at ${BACKUPDIR}/aggregate-olm-edit.yml not found!" 
 exit 1
fi

echo "Delete clusterrole aggregate-olm-edit [Y/N] ?"

read question1answer

if [ "$question1answer" !=  "${question1answer#[Yy]}" ]; then 
  echo "INFO: Test Deleting clusterrole aggregate-olm-edit"
    echo "Running ${KUBECTL} get clusterrole aggregate-olm-edit" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get clusterrole aggregate-olm-edit  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get clusterrole aggregate-olm-edit FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting  clusterrole aggregate-olm-edit ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/aggregate-olm-view.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/aggregate-olm-view.yml"
  else
   echo "ERROR : backup at ${BACKUPDIR}/aggregate-olm-view.yml not found!" 
 exit 1
fi

echo "Delete clusterrole aggregate-olm-view [Y/N] ?"

read question2answer

if [ "$question2answer" !=  "${question2answer#[Yy]}" ]; then 
 echo "Test Deleting clusterrole aggregate-olm-view"
    echo "Running ${KUBECTL} get clusterrole aggregate-olm-view" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get clusterrole aggregate-olm-view  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get clusterrole aggregate-olm-view FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting clusterrole aggregate-olm-view ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/catalog-operator.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/catalog-operator.yml"
  else
   echo "ERROR : backup at ${BACKUPDIR}/catalog-operator.yml not found!" 
 exit 1
fi

echo "Delete deployment catalog-operator -n ibm-system [Y/N] ?"

read question3answer

if [ "$question3answer" !=  "${question3answer#[Yy]}" ]; then 
 echo "Test Deleting  deploy catalog-operator -n ibm-system"
    echo "Running ${KUBECTL} get deployment catalog-operator -n ibm-system" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get deployment catalog-operator -n ibm-system >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get deployment catalog-operator -n ibm-system FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting  deployment catalog-operator -n ibm-system ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/olm-operator.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/olm-operator.yml "
  else
   echo "ERROR : backup at ${BACKUPDIR}/olm-operator.yml not found!" 
 exit 1
fi

echo "Delete deploymnet olm-operator -n ibm-system [Y/N] ?"

read question4answer

if [ "$question4answer" !=  "${question4answer#[Yy]}" ]; then 
 echo "Test Deleting  deployment olm-operator -n ibm-system"
     echo "Running ${KUBECTL} get deployment olm-operator -n ibm-system " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get deployment  olm-operator  -n ibm-system >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get deployment  olm-operator -n ibm-system FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting  deployment olm-operator -n ibm-system ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/system-controller-operator-lifecycle-manager.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/system-controller-operator-lifecycle-manager.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/system-controller-operator-lifecycle-manager.yml  not found!" 
 exit 1
fi

echo "Delete clusterrole system:controller:operator-lifecycle-manager [Y/N] ?"

read question5answer

if [ "$question5answer" !=  "${question5answer#[Yy]}" ]; then 
 echo "Test Deleting  clusterrole system:controller:operator-lifecycle-manager"
      echo "Running ${KUBECTL} get clusterrole system:controller:operator-lifecycle-manager" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get clusterrole system:controller:operator-lifecycle-manager >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get clusterrole system:controller:operator-lifecycle-manager FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting clusterrole system:controller:operator-lifecycle-manager ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/olm-operator-serviceaccount.yml  ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/olm-operator-serviceaccount.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/olm-operator-serviceaccount.yml  not found!" 
 exit 1
fi

echo "Delete serviceaccount olm-operator-serviceaccount -n ibm-system [Y/N] ?"

read question6answer

if [ "$question6answer" !=  "${question6answer#[Yy]}" ]; then 
 echo "Test Deleting serviceaccount olm-operator-serviceaccount -n ibm-system"
      echo "Running ${KUBECTL} get serviceaccount olm-operator-serviceaccount -n ibm-system" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get serviceaccount olm-operator-serviceaccount -n ibm-system >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get serviceaccount olm-operator-serviceaccount -n ibm-system FAILED !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting serviceaccount olm-operator-serviceaccount -n ibm-system  ... exiting "
 exit 1
fi
printf '\n' 
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/olm-operator-binding-ibm-system.yml ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/olm-operator-binding-ibm-system.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/olm-operator-binding-ibm-system.yml  not found!" 
 exit 1
fi

echo "Delete clusterrolebinding olm-operator-binding-ibm-system [Y/N] ?"

read question7answer

if [ "$question7answer" !=  "${question7answer#[Yy]}" ]; then 
 echo "Test Deleting clusterrolebinding olm-operator-binding-ibm-system"
      echo "Running ${KUBECTL} get clusterrolebinding olm-operator-binding-ibm-system " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get clusterrolebinding olm-operator-binding-ibm-system >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get clusterrolebinding olm-operator-binding-ibm-system !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting clusterrolebinding olm-operator-binding-ibm-system  ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/ibm-operators.yml  ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/ibm-operators.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/ibm-operators.yml   not found!" 
 exit 1
fi


echo "Delete operatorgroup ibm-operators -n ibm-operators [Y/N] ?"

read question8answer

if [ "$question8answer" !=  "${question8answer#[Yy]}" ]; then 
 echo "Test Deleting operatorgroup ibm-operators -n ibm-operators"
      echo "Running ${KUBECTL} get operatorgroup ibm-operators -n ibm-operators" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get operatorgroup ibm-operators -n ibm-operators >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get operatorgroup ibm-operators -n ibm-operators !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting operatorgroup ibm-operators -n ibm-operators   ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/olm-operatorgroup-operators.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/olm-operatorgroup-operators.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/olm-operatorgroup-operators.yml   not found!" 
 exit 1
fi

echo "Delete operatorgroup olm-operators -n ibm-system [Y/N] ?"

read question9answer

if [ "$question9answer" !=  "${question9answer#[Yy]}" ]; then 
 echo "Test Deleting operatorgroup olm-operators -n ibm-system"
       echo "Running ${KUBECTL} get operatorgroup olm-operators -n ibm-system " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get operatorgroup olm-operators -n ibm-system  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get operatorgroup ibm-operators -n ibm-operators !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting operatorgroup olm-operators -n ibm-system  ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/catalog-operator-metrics.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/catalog-operator-metrics.yml   "
  else
   echo "ERROR : backup at ${BACKUPDIR}/catalog-operator-metrics.yml not found!" 
 exit 1
fi

echo "Delete service catalog-operator-metrics -n ibm-system [Y/N] ?"

read question10answer

if [ "$question10answer" !=  "${question9answer#[Yy]}" ]; then 
 echo "Test Deleting service catalog-operator-metrics -n ibm-system"
       echo "Running ${KUBECTL} get service catalog-operator-metrics -n ibm-system " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get service catalog-operator-metrics -n ibm-system  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get service catalog-operator-metrics -n ibm-system !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting service catalog-operator-metrics -n ibm-system  ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/olm-operator-metrics.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/olm-operator-metrics.yml "
  else
   echo "ERROR : backup at ${BACKUPDIR}/olm-operator-metrics.yml  not found!" 
 exit 1
fi

echo "Delete service olm-operator-metrics -n ibm-system [Y/N] ?"

read question11answer

if [ "$question11answer" !=  "${question11answer#[Yy]}" ]; then 
 echo "Test Deleting service olm-operator-metrics -n ibm-system"
        echo "Running ${KUBECTL} get service olm-operator-metrics -n ibm-system " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get service olm-operator-metrics -n ibm-system >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get service olm-operator-metrics -n ibm-system !"
      else
     echo "INFO: Successfully deleted"
    fi
  else 
 echo "NOT Test Deleting service olm-operator-metrics -n ibm-system ... exiting "
 exit 1
fi
printf '\n'
#####################################################################
}


function DeleteCRD {
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/catalogsources-operators-coreos-com.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/catalogsources-operators-coreos-com.yml "
  else
   echo "ERROR : backup at ${BACKUPDIR}/catalogsources-operators-coreos-com.yml  not found!" 
 exit 1
fi

echo "Delete CRD catalogsources.operators.coreos.com [Y/N] ?"

read question12answer

if [ "$question12answer" !=  "${question12answer#[Yy]}" ]; then 
 echo "Test Deleting CRD catalogsources.operators.coreos.com"
        echo "Running ${KUBECTL} get catalogsources.operators.coreos.com" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get catalogsources.operators.coreos.com -A >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get catalogsources.operators.coreos.com !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD catalogsources.operators.coreos.com ... exiting "
 exit 1
fi 
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.yml   not found!" 
 exit 1
fi

echo "Delete CRD clusterserviceversions.operators.coreos.com [Y/N] ?"

read question13answer

if [ "$question13answer" !=  "${question12answer#[Yy]}" ]; then 
 echo "Test Deleting CRD clusterserviceversions.operators.coreos.com "
         echo "Running ${KUBECTL} get crd clusterserviceversions.operators.coreos.com" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get clusterserviceversions.operators.coreos.com -A >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get clusterserviceversions.operators.coreos.com  !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD clusterserviceversions.operators.coreos.com  ... exiting "
 exit 1
fi 
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/installplans-operators-coreos-com.yml   ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/installplans-operators-coreos-com.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/installplans-operators-coreos-com.yml   not found!" 
 exit 1
fi

echo "Delete CRD installplans.operators.coreos.com [Y/N] ?"

read question14answer

if [ "$question14answer" !=  "${question14answer#[Yy]}" ]; then 
 echo "Test Deleting CRD installplans.operators.coreos.com "
         echo "Running ${KUBECTL} get installplans.operators.coreos.com " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get installplans.operators.coreos.com -A  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get installplans.operators.coreos.com  !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD installplans.operators.coreos.com ... exiting "
 exit 1
fi 
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/operatorgroups-operators-coreos-com.yml    ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/operatorgroups-operators-coreos-com.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/operatorgroups-operators-coreos-com.yml    not found!" 
 exit 1
fi

echo "Delete CRD operatorgroups.operators.coreos.com [Y/N] ?"

read question15answer

if [ "$question15answer" !=  "${question15answer#[Yy]}" ]; then 
 echo "Test Deleting CRD operatorgroups.operators.coreos.com  "
         echo "Running ${KUBECTL} get operatorgroups.operators.coreos.com " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get operatorgroups.operators.coreos.com  -A  >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get operatorgroups.operators.coreos.com  !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD operatorgroups.operators.coreos.com  ... exiting "
 exit 1
fi 
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/operators-operators-coreos-com.yml    ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/operators-operators-coreos-com.yml  "
  else
   echo "ERROR : backup at ${BACKUPDIR}/operators-operators-coreos-com.yml  not found!" 
 exit 1
fi

echo "Delete CRD operators.operators.coreos.com [Y/N] ?"

read question16answer

if [ "$question16answer" !=  "${question16answer#[Yy]}" ]; then 
 echo "Test Deleting CRD operators.operators.coreos.com  "
         echo "Running ${KUBECTL} get operators.operators.coreos.com   " >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get operators.operators.coreos.com  -A >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} get operators.operators.coreos.com  !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD operators.operators.coreos.com  ... exiting "
 exit 1
fi 
printf '\n'
#####################################################################
date +%x%t%T | awk '{print $2":"$1}' >> ${DELETELOG}

if [ -f ${BACKUPDIR}/subscriptions-operators-coreos-com.yml    ]; then
   echo "INFO : Found backup at ${BACKUPDIR}/subscriptions-operators-coreos-com.yml"
  else
   echo "ERROR : backup at ${BACKUPDIR}/subscriptions-operators-coreos-com.yml  not found!" 
 exit 1
fi

echo "Delete CRD subscriptions.operators.coreos.com [Y/N] ?"

read question17answer

if [ "$question17answer" !=  "${question17answer#[Yy]}" ]; then 
 echo "Test Deleting CRD subscriptions.operators.coreos.com"
         echo "Running ${KUBECTL} get subscriptions.operators.coreos.com" >> ${DELETELOG} 2>&1
# Delete object kubectl command below. Output and errors are directed to log file  
    ${KUBECTL} get subscriptions.operators.coreos.com  -A >> ${DELETELOG} 2>&1
    if [ $? != '0' ]; then
     echo "ERROR: ${KUBECTL} delete crd subscriptions.operators.coreos.com !"
      else
     echo "INFO: Successfully deleted"
    fi 
  else 
 echo "NOT Test Deleting CRD subscriptions.operators.coreos.com ... exiting"
 exit 1
fi   
}
printf '\n'
################################################# MAIN #######################################################

echo "######################################################################"
echo "#                                                                    #"
echo "#          Test Script Delete IBM IKS OLM Operator Objects           #"
echo "#                                                                    #"
echo "#    Script to test the delete functions in delete-olm-operator.sh   #"
echo "######################################################################"
echo "usage : bash test-delete-olm-operator.sh /path/to/backup"


if [ ${AGENT_OS} != "Linux" ]; then
 echo "ERROR : Execution on Linux Only"
  exit 1
  else
echo "DEBUG : Executing on Linux"
fi

if [ -z ${K8SENV} ]; then
 echo "ERROR : K8SENV variable not set"
  exit 1
 else
 echo "INFO : K8SENV variable set to ${K8SENV} "
fi

if [ -z ${BACKUPDIR} ]; then
 echo "ERROR : BACKUPDIR variable not provided !"
  exit 1
 else
 echo "INFO : BACKUPDIR variable set to ${BACKUPDIR} "
fi

if [ -f ${BACKUPDIR} ]; then
 echo "ERROR : ${BACKUPDIR} does not exist !"
  exit 1
 else
 echo "INFO : ${BACKUPDIR} found "
fi

if [ -z ${CLUSTERID} ]; then
 echo "ERROR : CLUSTERID variable not set"
  exit 1
 else
 echo "INFO : CLUSTERID variable set to ${CLUSTERID} "
fi

mkdir ${OUTPUTDIR}

echo "GetOLMOperator -> Step 1 : Confirm whether or not you have the OLM operator installed"
GetOLMOperator
sleep 10
echo "GetOLMAddons -----> Step 2 : If the OLM operator is installed in your cluster, check if it is in use"
GetOLMAddons
sleep 10
echo "DeleteOLM -----------> Step 3 : If you determined that OLM is not used by the Istio add-on or any additional operators, run each command below individually to delete OLM resources."
DeleteOLM
echo "DeleteCRD ----------------> Step 4 : If you determined that OLM is not used by the Istio add-on or any additional operators, delete any unused custom resource definitions (CRD) that were installed by OLM."
OutputCRDdetails
DeleteCRD