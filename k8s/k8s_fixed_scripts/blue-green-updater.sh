#!/bin/bash

NAMESPACE=$1
INGRESS_NAME=$2
BLUE_WEIGHT=$3
GREEN_WEIGHT=$4

if [ -z "$BLUE_WEIGHT" ] || [ -z "$GREEN_WEIGHT" ]; then
  echo "Algunos parametros estan vacios, se debe introducir al menos un valor con 100 si el otro vale 0."
  exit 1
fi
echo "Parametros recibidos: Blue=$BLUE_WEIGHT, Green=$GREEN_WEIGHT"

# Validar que sumen 100
TOTAL=$((BLUE_WEIGHT + GREEN_WEIGHT))
if [ $TOTAL -ne 100 ]; then
  echo "Error: los pesos no suman 100, actual => $TOTAL)"
  exit 1
fi
echo "Los pesos suman 100, procediendo a actualizar el Ingress."

ANNOTATION_VALUE="{\"type\":\"forward\",\"forwardConfig\":{\"targetGroups\":[{\"serviceName\":\"app-blue-service\",\"servicePort\":\"80\",\"weight\":${BLUE_WEIGHT}},{\"serviceName\":\"app-green-service\",\"servicePort\":\"80\",\"weight\":${GREEN_WEIGHT}}]}}"

echo "Nuevo valor de la anotacion: $ANNOTATION_VALUE"

PATCH=$(jq -n \
  --arg value "$ANNOTATION_VALUE" \
  '[{
     "op": "replace",
     "path": "/metadata/annotations/alb.ingress.kubernetes.io~1actions.weighted-routing",
     "value": $value
  }]')

kubectl patch ingress $INGRESS_NAME -n $NAMESPACE --type='json' -p="$PATCH"

echo "Traffic updated: Blue=$BLUE_WEIGHT%, Green=$GREEN_WEIGHT%"
