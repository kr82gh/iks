#!/bin/bash
AGENT_OS=`uname`
KUBECTL=`which kubectl`
LOGDATE=`date +%F%t%T | sed 's/:/-/g' | awk '{print $1"-"$2}'`
BACKUPLOG="backup-olm-${LOGDATE}.log"
BACKUPDIR="backups-${LOGDATE}"
############################

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
KSOLMCOUNT=`${KUBECTL} get clusterserviceversions.operators.coreos.com -A  | grep -v  VERSION  | wc -l`
if [ ${KSOLMCOUNT} != "0" ]; then
 echo "WARN : Cluster addons installed via OLM in ${CLUSTERID} in NS ibm-system"
fi
}

function GetOLMAddons {
echo "DEBUG : Running - 'ibmcloud ks cluster addons -c ${CLUSTERID} | grep -v NAME | wc -l' "
# Check for Rancher local dev
if [ ${K8SENV} != "Rancher" ]; then
KSCOUNT=`ibmcloud ks cluster addons -c ${CLUSTERID} | grep -A 1  NAME  | wc -l`
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
${KUBECTL} get operatorgroup olm-operatorgroup-operators -n ibm-system \
           -o=yaml >  ${BACKUPDIR}/olm-operators.yml  2>> ${BACKUPLOG}
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
${KUBECTL} get catalogsources.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/catalogsources-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get clusterserviceversions.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/clusterserviceversions-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get installplans.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/installplans-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operatorgroups.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/operatorgroups-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get operators.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/operators-operators-coreos-com.yml  2>> ${BACKUPLOG}
sleep 10
date +%x%t%T | awk '{print $2":"$1}' >> ${BACKUPLOG} 
${KUBECTL} get subscriptions.operators.coreos.com -A \
            -o=yaml >  ${BACKUPDIR}/subscriptions-operators-coreos-com.yml  2>> ${BACKUPLOG}    
}

#############################MAIN########################
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
echo "BackupOLM -----------> Step 4 : If you determined that OLM is not used by the Istio add-on or any additional operators, delete any unused custom resource definitions (CRD) that were installed by OLM."
BackupCRD
sleep 10
if [ $? != "0" ]; then
 echo "ERROR : Failed to backup CRDs" 
  exit 1
fi
