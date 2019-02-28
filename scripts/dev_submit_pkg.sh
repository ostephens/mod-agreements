#!/bin/sh


if [ -f ~/folio_privates.sh ]
then
  echo Loading folio_privates script
  . ~/folio_privates.sh
fi

echo Configured::
echo $EBSCO_SANDBOX_CLIENT_ID

# jq -r '.name'

echo Testing for presence of JQ

JQTEST=`echo '{  "value":"one" }' | jq -r ".value" | tr -d '\r'`

if [ $JQREST="one" ]
then
  echo JQ installed and working
else
  echo Please install JQ
  exit 1
fi

echo Running

FOLIO_AUTH_TOKEN=`okapi_login`
FOLIO_BASE_URL="http://localhost:3000"
TENANT="diku"

# Run OKAPI commands with
# curl -sSL -XGET -H "X-Okapi-Token: ${FOLIO_AUTH_TOKEN}" -H 'accept: application/json' -H 'Content-type: application/json' -H "X-Okapi-Tenant: $TENANT" --connect-timeout 5 --max-time 30 "${OKAPI}${URI}"

# Prepolpulate with data.
echo Loading k-int test package
KI_PKG_ID=`curl --header "X-Okapi-Tenant: diku" -X POST -F package_file=@../service/src/integration-test/resources/packages/simple_pkg_1.json http://localhost:8080/erm/admin/loadPackage | jq -r ".packageId"  | tr -d '\r'`

echo loading betham science
BSEC_PKG_ID=`curl --header "X-Okapi-Tenant: diku" -X POST -F package_file=@../service/src/integration-test/resources/packages/bentham_science_bentham_science_eduserv_complete_collection_2015_2017_1386.json http://localhost:8080/erm/admin/loadPackage | jq -r ".packageId" | tr -d '\r'`

echo Loading APA
APA_PKG_ID=`curl --header "X-Okapi-Tenant: diku" -X POST -F package_file=@../service/src/integration-test/resources/packages/apa_1062.json http://localhost:8080/erm/admin/loadPackage | jq -r ".packageId" | tr -d '\r'`

STATUS_DRAFT_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/agreementStatus | jq -r '.[] | select(.label=="Draft") | .id'`
STATUS_ACTIVE_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/agreementStatus | jq -r '.[] | select(.label=="Active") | .id'`
ISPERPETUAL_YES_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/isPerpetual | jq -r '.[] | select(.label=="Yes") | .id'`
ISPERPETUAL_NO_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/isPerpetual | jq -r '.[] | select(.label=="No") | .id'`
RENEW_DEFRENEW_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/renewalPriority | jq -r '.[] | select(.label=="Definitely Renew") | .id'`
RENEW_REVIEW_RDV=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreement/renewalPriority | jq -r '.[] | select(.label=="For Review") | .id'`
ROLE_CONTENT_PROVIDER=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" http://localhost:8080/erm/refdataValues/SubscriptionAgreementOrg/role | jq -r '.[] | select(.label=="Content Provider") | .id'`

# Find the package content item entitle for Clinical Cancer Drugs in K-Int Test Package 001
CCD_IN_KI_TEST_PKG=`curl --header "X-Okapi-Tenant: diku" "http://localhost:8080/erm/pci?filters=pti.titleInstance.title%3D%3DClinical+Cancer+Drugs&filters=pkg.name%3D%3DK-Int+Test+Package+001" -X GET | jq -r ".[0].id" | tr -d '\r'`


echo Create a trial agreement

# Create an agreement - Vendor ID generated by uuidgen here, in reality would be fetched from vendor service
TRIAL_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Trial Agreement LR 001",
  description: "This is a trial agreement",
  agreementStatus: { id: "'"$STATUS_DRAFT_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_YES_RDV"'" },
  renewalPriority: { id: "'"$RENEW_REVIEW_RDV"'" },
  localReference: "TRIAL_ALR_001",
  vendorReference: "TRIAL_AVR_001",
  startDate: "2018-01-01",
  endDate: "2019-12-31",
  renewalDate: "2019-01-01",
  nextReviewDate: "2018-10-01",
  vendor: {
    vendorsUuid: "05f327a6-c4d3-43c2-828f-7d6e7e401c99",
    name:"My Super Vendor",
    sourceURI:"/vendors/some/uri?05f327a6-c4d3-43c2-828f-7d6e7e401c99"
  },
  items: [
    {
      resource : { id : "'"$BSEC_PKG_ID"'" }
    }
  ],
  "docs": [
    { "name": "A test document attachment", "location":"sent in, sent back, queried, lost, found, subjected to public inquiry, lost again, and finally buried in soft peat for three months and recycled as firelighters.", "url":"http://a.b.c/d/e/f.doc", "note":"This is a document attachment",  "atType":"License" }
  ],
  "externalLicenseDocs": [
    { "name": "An External license document", "location":"sent in, sent back, queried, lost, found, subjected to public inquiry, lost again, and finally buried in soft peat for three months and recycled as firelighters.", "url":"http://a.b.c/d/e/f.doc", "note":"This is a document attachment",  "atType":"License" }
  ],
  tags: [
    {value: "Legacy"},
    "Other value",
    "legacy"
  ],
  orgs: [
    {
      role: "Content Provider",
      org: {
        vendorsUuid: "05f327a6-c4d3-43c2-828f-7d6e7e401c97",
        name: "A test content provider org"
      }
    }
  ]
}
' | jq -r ".id" | tr -d '\r'`

echo Create an active agreement

# Create an agreement
ACTIVE_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Active Agreement LR 002",
  description: "This is an active agreement",
  agreementStatus: { id: "'"$STATUS_ACTIVE_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_NO_RDV"'" },
  renewalPriority: { id: "'"$RENEW_DEFRENEW_RDV"'" },
  localReference: "AGG_LR_002",
  vendorReference: "AGG_VR_002",
  startDate: "2018-01-01",
  vendor: {
    vendorsUuid: "05f327a6-c4d3-43c2-828f-7d6e7e401c99",
    name:"My Super Vendor",
    sourceURI:"/vendors/some/uri?05f327a6-c4d3-43c2-828f-7d6e7e401c99"
  },
  items: [
    {
      resource : { id : "'"$CCD_IN_KI_TEST_PKG"'" }
    }
  ]
}
' | jq -r ".id" | tr -d '\r'`

ELSEVIER_FC_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Freedom Collection",
  description: "An agreement that describes all the content that we buy from Elsevier",
  agreementStatus: { id: "'"$STATUS_ACTIVE_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_NO_RDV"'" },
  renewalPriority: { id: "'"$RENEW_DEFRENEW_RDV"'" },
  localReference: "AGG_LR_002",
  vendorReference: "AGG_VR_002",
  startDate: "2018-01-01",
  vendor: {
    name:"Elsevier"
  },
  items: [
  ]
}
' | jq -r ".id" | tr -d '\r'`

WILEY_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Wiley Test Agreement",
  description: "An agreement that describes all the content that we buy from Wiley",
  agreementStatus: { id: "'"$STATUS_ACTIVE_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_NO_RDV"'" },
  renewalPriority: { id: "'"$RENEW_DEFRENEW_RDV"'" },
  localReference: "AGG_LR_002",
  vendorReference: "AGG_VR_002",
  startDate: "2018-01-01",
  vendor: {
    name:"Wiley"
  },
  items: [
  ]
}
' | jq -r ".id" | tr -d '\r'`

SPRINGER_NATURE_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Springer Nature",
  description: "An agreement that describes all the content that we access via Springer Nature",
  agreementStatus: { id: "'"$STATUS_ACTIVE_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_NO_RDV"'" },
  renewalPriority: { id: "'"$RENEW_DEFRENEW_RDV"'" },
  localReference: "AGG_LR_002",
  vendorReference: "AGG_VR_002",
  startDate: "2018-01-01",
  vendor: {
    name:"Springer"
  },
  items: [
  ]
}
' | jq -r ".id" | tr -d '\r'`

BENTHAM_EXTERNAL_AGREEMENT_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/sas -d '
{
  name: "Bentham Science (External/EKB)",
  description: "This agreement is a test case for where the content an agreement provides access to is defined externally - in this case EKB vendor 301/package 3707.",
  agreementStatus: { id: "'"$STATUS_ACTIVE_RDV"'" },
  isPerpetual: { id: "'"$ISPERPETUAL_NO_RDV"'" },
  renewalPriority: { id: "'"$RENEW_DEFRENEW_RDV"'" },
  localReference: "EBSCO_TC1",
  vendorReference: "301:3707",
  startDate: "2018-01-01",
  vendor: {
    name:"Bentham Science"
  },
  items: [
    { type:"external", authority:"EKB", reference:"301-3707", label:"Bentham Science via eHoldings" },
    { type:"external", authority:"EKB", reference:"19-1615", label:"Academic Source Complete via eHoldings" }
  ]
}
' | jq -r ".id" | tr -d '\r'`

# Lets see if we can list agreements by the EKB references they contain
echo List agreements containing the externally referenced package "301-3707"
curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X GET "http://localhost:8080/erm/sas?filters=items.reference%3d301-3707&stats=true"

# These are the 2 items which define a package in EKB, however, it looks like the query in
# grails-app/controllers/org/olf/SubscriptionAgreementController.groovy gets confused. For now
# commenting these out. Will talk this through with steve tomorrow.




echo Look up package content item ID for CCD in the k-int test package


# List agreements
# AGREEMENT_ID=`curl --header "X-Okapi-Tenant: ${TENANT}" http://localhost:8080/erm/sas -X GET | jq ".[0].id" | tr -d '\r'`
# List packages
# We now get the package back when we load the package above, this is still a cool way to work tho
# PACKAGE_ID=`curl --header "X-Okapi-Tenant: ${TENANT}" http://localhost:8080/erm/packages?stats=true -X GET | jq ".[0].id" | tr -d '\r'`

echo Add a KB record describing KB+
# Register a remote source
RS_KBPLUS_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/kbs -d '
{
  name:"KB+",
  type:"org.olf.kb.adapters.KIJPFAdapter", // K-Int Json Package Format Adapter
  cursor:null,
  uri:"https://www.kbplus.ac.uk/kbplus7/publicExport/idx",
  listPrefix:null,
  fullPrefix:null,
  principal:null,
  credentials:null,
  rectype:"1",
  active:false,
  supportsHarvesting:true
}
'`
# The GOKb_TEST adapter used to be created here - this has moved to the tenant activation section of org.olf.ErmHousekeepingService

if [ -z "$EBSCO_SANDBOX_CLIENT_ID" ]
then
  echo "No Ebsco API credentials set, skipping pull package"
else
  echo Add a KB record describing EBSCO sandbox API

  RS_EBSCO_ID=`curl --header "X-Okapi-Tenant: diku" -H "Content-Type: application/json" -X POST http://localhost:8080/erm/kbs -d '
{
  name:"EBSCO",
  type:"org.olf.kb.adapters.EbscoKBAdapter",
  cursor:null,
  uri:"https://sandbox.ebsco.io",
  listPrefix:null,
  principal:"'"$EBSCO_SANDBOX_CLIENT_ID"'",
  credentials:"'"$EBSCO_SANDBOX_API_KEY"'",
  rectype:"1",
  active:false,
  supportsHarvesting:false,
  activationSupported:true,
  activationEnabled:true,
}
'`

  echo Import EBSCO Bentham Science Package
  EBSCO_BENTHAM_SCI_ID=`curl --header "X-Okapi-Tenant: diku" -X POST "http://localhost:8080/erm/admin/pullPackage?kb=EBSCO&vendorid=301&packageid=3707" | jq -r ".packageId"  | tr -d '\r'`
  echo Result of loading bentham sci from ebsco: $EBSCO_BENTHAM_SCI_ID.

  # Load academic source complete - a good test case for large package ingest performance and test case for title create transaction boundary
  # Message from Ian: don't do this without talking to EBSCO first - 
  # EBSCO_ACADEMIC_SOURCE_COMPLETE_ID=`curl --header "X-Okapi-Tenant: diku" -X POST "http://localhost:8080/erm/admin/pullPackage?kb=EBSCO&vendorid=19&packageid=1615" | jq -r ".packageId"  | tr -d '\r'`
  # echo Result of loading academic source complete from ebsco: $EBSCO_ACADEMIC_SOURCE_COMPLETE_ID.
fi


# If all goes well, you'll get a status message back. After that, try searching your subscribed titles:

echo GET page 1 of subscribed content
curl --header "X-Okapi-Tenant: diku" http://localhost:8080/erm/content -X GET


# Or try the codex interface instead
#curl --header "X-Okapi-Tenant: diku" http://localhost:8080/codex-instances -X GET

# Pull an ID from that record and ask the codex interface for some details
#RECORD_ID="ff80818162a5e9600162a5e9ef63002f"
#curl --header "X-Okapi-Tenant: diku" http://localhost:8080/codex-instances/$RECORD_ID -X GET

echo dev_submit_pkg.sh completed
