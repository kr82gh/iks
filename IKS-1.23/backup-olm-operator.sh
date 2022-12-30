#!/bin/bash
#######################################################################################################################
AGENT_OS=`uname`                                                                                                      #
KUBECTL=`which kubectl`                                                                                               #
LOGDATE=`date +%F%t%T | sed 's/:/-/g' | awk '{print $1"-"$2}'`                                                        #
BACKUPLOG="backup-olm-${LOGDATE}.log"                                                                                 #
BACKUPDIR="backups-${LOGDATE}"                                                                                        #
#######################################################################################################################

function GetOLMOperator {
${KUBECTL} get deploy olm-operator -n ibm-system  -o=yaml  > ${BACKUPDIR}/olm-operator-deployment.yml  2>> ${BACKUPLOG} 

if [ $? != "0" ]; then
 echo "ERROR : Failed to get OLM Deployment in Namespace ibm-system" 
  exit 1
 else
 echo "INFO : ibm-system ns exists with OLM Deployment"
fi
}


function GetOLMDeployedAddons {
echo "INFO : Checking if Addons were installed via OLM on ${CLUSTERID} in NS ibm-system"
${KUBECTL} get clusterserviceversions.operators.coreos.com -A > ${BACKUPDIR}/${CLUSTERID}addons-olm-managed.txt 2>&1 

if [ -f ${BACKUPDIR}/${CLUSTERID}addons-olm-managed.txt ]; then
   echo "DEBUG : ${BACKUPDIR}/${CLUSTERID}addons-olm-managed.txt exists" >> ${BACKUPLOG} 2>&1 
  else
   echo "ERROR : ${BACKUPDIR}/${CLUSTERID}addons-olm-managed.txt DOES NOT EXIST !" 
 exit 1
fi

KSOLMCOUNT=`egrep -v 'No resources found' ${BACKUPDIR}/${CLUSTERID}addons-olm-managed.txt  | wc -l`
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
echo "DEBUG : Running - 'grep -A 1  Name ${BACKUPDIR}/${CLUSTERID}-addons.txt| egrep '^Name.*' |  wc -l' >> ${BACKUPLOG} 2>&1" 
ibmcloud ks cluster addons -c ${CLUSTERID} > ${BACKUPDIR}/${CLUSTERID}-addons.txt
if [ -f ${BACKUPDIR}/${CLUSTERID}-addons.txt ]; then
   echo "DEBUG : ${BACKUPDIR}/${CLUSTERID}-addons.txt exists" >> ${BACKUPLOG} 2>&1 
  else
   echo "ERROR : ${BACKUPDIR}/${CLUSTERID}-addons.txt DOES NOT EXIST !" 
 exit 1
fi
KSCOUNT=`grep -A 1  Name ${BACKUPDIR}/${CLUSTERID}-addons.txt| egrep '^Name.*' |  wc -l`
 else
KSCOUNT="0"
fi 

if [ ${KSCOUNT} != "0" ]; then
 echo "WARN : Cluster addons in use in ${CLUSTERID} in NS ibm-system"
 GetOLMDeployedAddons
  else 
 echo "INFO : Cluster addons NOT in use in ${CLUSTERID} in NS ibm-system"
fi
}

function BackupOLM {
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterrole aggregate-olm-edit \
           -o=yaml > ${BACKUPDIR}/aggregate-olm-edit.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterrole aggregate-olm-view \
           -o=yaml > ${BACKUPDIR}/aggregate-olm-view.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get deploy catalog-operator -n ibm-system \
           -o=yaml > ${BACKUPDIR}/catalog-operator.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get deploy olm-operator -n ibm-system \
           -o=yaml > ${BACKUPDIR}/olm-operator.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterrole system:controller:operator-lifecycle-manager \
           -o=yaml > ${BACKUPDIR}/system-controller-operator-lifecycle-manager.yml  2>> ${BACKUPLOG} 
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get serviceaccount olm-operator-serviceaccount -n ibm-system  \
           -o=yaml > ${BACKUPDIR}/olm-operator-serviceaccount.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterrolebinding olm-operator-binding-ibm-system \
           -o=yaml > ${BACKUPDIR}/olm-operator-binding-ibm-system.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operatorgroup ibm-operators -n ibm-operators   \
           -o=yaml > ${BACKUPDIR}/ibm-operators.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operatorgroup olm-operators -n ibm-system \
           -o=yaml >  ${BACKUPDIR}/olm-operatorgroup-operators.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get service catalog-operator-metrics -n ibm-system \
           -o=yaml >  ${BACKUPDIR}/catalog-operator-metrics.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get service olm-operator-metrics -n ibm-system \
           -o=yaml >  ${BACKUPDIR}/olm-operator-metrics.yml  2>> ${BACKUPLOG}
}

function BackupCRD {
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd catalogsources.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/catalogsources-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd clusterserviceversions.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd installplans.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/installplans-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd operatorgroups.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/operatorgroups-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd operators.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/operators-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get crd subscriptions.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/subscriptions-operators-coreos-com.yml  2>> ${BACKUPLOG}    
}


function GetCRDDetails {
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get  catalogsources.operators.coreos.com -A  >  ${BACKUPDIR}/catalogsources-operators-coreos-com.txt  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterserviceversions.operators.coreos.com -A >  ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.txt  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get installplans.operators.coreos.com -A >  ${BACKUPDIR}/installplans-operators-coreos-com.txt  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operatorgroups.operators.coreos.com -A >  ${BACKUPDIR}/operatorgroups-operators-coreos-com.txt  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operators.operators.coreos.com -A >  ${BACKUPDIR}/operators-operators-coreos-com.txt  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get subscriptions.operators.coreos.com -A >  ${BACKUPDIR}/subscriptions-operators-coreos-com.txt  2>> ${BACKUPLOG}  


################################################# MAIN #######################################################

echo "#########################################################"
echo "#                                                       #"
echo "#          Backup IBM IKS OLM Operator Objects          #"
echo "#                                                       #"
echo "#########################################################"

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

if [ -z ${CLUSTERID} ]; then
 echo "ERROR : CLUSTERID variable not set"
  exit 1
 else
 echo "INFO : CLUSTERID variable set to ${CLUSTERID} "
fi

mkdir ${BACKUPDIR}

echo "GetOLMOperator -> Step 1 : Confirm whether or not you have the OLM operator installed"
GetOLMOperator
sleep 10
echo "GetOLMAddons -----> Step 2 : If the OLM operator is installed in your cluster, check if it is in use"
GetOLMAddons
sleep 10
echo "BackupOLM -----------> Step 3 : If you determined that OLM is not used by the Istio add-on or any additional operators, run each command below individually to delete OLM resources."
BackupOLM
sleep 10
if [ $? != "0" ]; then
 echo "ERROR : Failed to backup OLM objects" 
  exit 1
fi
echo "BackupCRD ----------------> Step 4 : If you determined that OLM is not used by the Istio add-on or any additional operators, delete any unused custom resource definitions (CRD) that were installed by OLM."
BackupCRD
sleep 10
if [ $? != "0" ]; then
 echo "ERROR : Failed to backup CRDs" 
  exit 1
fi
cho "GetCRDDetails ----------------> Step 4 Cont: Get the details of each CR to determine if it is used."
GetCRDDetails
sleep 10
if [ $? != "0" ]; then
 echo "ERROR : Failed to get CRD details" 
  exit 1
fi
