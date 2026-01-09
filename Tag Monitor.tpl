___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Tag Monitor",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Monitor de tags que avalia o retorno da execução das mesmas e dispara o evento \"throw_error\" no data layer, com as informações de id, status, tag_name e execution_time.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "label",
    "displayName": "Insira o metadado \"tagName\" nas tags que deseja monitorar para que o parâmetro seja enviado. Para adicionar, selecione a tag desejada, vá em \"Configurações avançadas \u003e Metadados de tag adicionais \u003e Incluir o nome da tag\" e digite \"tagName\"."
  },
  {
    "type": "SELECT",
    "name": "event",
    "displayName": "Variável {{Event}}",
    "macrosInSelect": true,
    "selectItems": [],
    "simpleValueType": true,
    "help": "Sempre deixe a variável {{Event}} para o bom funcionamento da tag"
  },
  {
    "type": "RADIO",
    "name": "typeButton",
    "displayName": "Condição de disparo",
    "radioItems": [
      {
        "value": "event",
        "displayValue": "Evento no data layer",
        "help": "Nome do evento no data layer. Retornará as tags que disparam com o evento escolhido. Para mais de um evento, digite separado por vírgula e sem espaços, por exemplo \"evento1,evento2,evento3,...\"",
        "subParams": [
          {
            "type": "TEXT",
            "name": "eventText",
            "displayName": "",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ]
      },
      {
        "value": "tagName",
        "displayValue": "Nome da tag",
        "help": "Nome das tags, separadas por vírgula e sem espaços entre elas, por exemplo \"tag 1,tag_2,tag3,...\".\nObs.: As tags precisam possuir o metadado \"tagName\"",
        "subParams": [
          {
            "type": "TEXT",
            "name": "tagNameText",
            "displayName": "",
            "simpleValueType": true,
            "valueValidators": [
              {
                "type": "NON_EMPTY"
              }
            ]
          }
        ]
      }
    ],
    "simpleValueType": true,
    "help": "Insira a condição que deseja para que a tag envie os dados de monitoramento ao GA4.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "statusGroup",
    "displayName": "Status da tag",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "success",
        "checkboxText": "success",
        "simpleValueType": true
      },
      {
        "type": "CHECKBOX",
        "name": "failure",
        "checkboxText": "failure",
        "simpleValueType": true
      },
      {
        "type": "CHECKBOX",
        "name": "exception",
        "checkboxText": "exception",
        "simpleValueType": true
      },
      {
        "type": "CHECKBOX",
        "name": "timeout",
        "checkboxText": "timeout",
        "simpleValueType": true
      }
    ],
    "help": "Selecione os status que deseja monitorar. Lembrando que, quanto mais status selecionados, mais dados serão enviados ao Data Lake"
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const log = require('logToConsole');
const addEventCallback = require('addEventCallback');
const callInWindow = require('callInWindow');
const JSON = require('JSON');
const Object = require('Object');
const sendPixel = require('sendPixel');
const getCookieValues = require('getCookieValues');
const getUrl = require('getUrl');
const getTimestampMillis = require('getTimestampMillis');

// Evento atual no data layer
const event = data.event;

// Evento que será enviado ao data layer para disparar a tag de erro, conforme documentações internas 
const EVENT_TO_IGNORE = 'throw_error'; 
const typeButton = data.typeButton;
const endpoint = 'https://script.google.com/a/macros/gruposbf.com.br/s/AKfycbyf93mSuredGdIkSQ5-W6xqhuZFLZKIXfR3QRhpId8jQhyp-JILOPTmiG2-ZV4-P_yDwQ/exec';

// Filtro dos status selecionados para serem enviados
const tagStatus = Object.entries(data).filter((p) => {
    return p[0].match("^exception$|^success$|^failure$|^timeout$");
  }).filter((e) => {
    return e[1]==true;
  }).map((s) => {
    return s[0];
  });

// Função que envia os dados ao data layer para disparar a tag de erro
const pushDl = (eventName, tagId, tagName, status, executionTime) => {
  callInWindow('newDataLayer.push', 
    {
      'event': eventName,
      'tag_id': tagId,
      'tag_name': tagName,
      'status': status,
      'execution_time': executionTime
    });
};


// API que retorna informações das tags após o disparo
addEventCallback((containerID, eventData) => {
  // Ignora o evento que é enviado ao data layer por essa tag para não entrar em loop
  if(event == EVENT_TO_IGNORE){
    return;
  } else {
    const tags = eventData['tags']; // Tags disparadas no evento
    // Eventos do data layer, separados por vírgula
    if(typeButton == 'event'){
      const eventText = data.eventText.split(',');
      // Loop que utiliza as informações de evento inseridas na tag, checa se é igual ao evento disparado no site e se o status de retorno é igual
      /* eventText 
           => event
             =>  status
      */ 
      eventText.forEach((dlEvent) => {
        if(dlEvent == event){
          tags.forEach((tags) => {
            tagStatus.forEach((status) => {
              if(tags.status == status){
                // Push no data layer com as informações de retorno da API
                pushDl(EVENT_TO_IGNORE, tags.id, tags.tagName, tags.status, tags.executionTime);
              }
            });
          });
        }
      });
    // Nome das tags, separados por vírgula
    } else {
      const tagNameText = data.tagNameText.split(',');
      // Loop que utiliza os nomes das tags específicas inseridas na tag, checa se é igual ao tagName retornado pela API e se o status de retorno é igual
      /* tagNameText 
           => tags.tagName
             =>  status
      */ 
      tagNameText.forEach((tagNameT) => {
        tags.forEach((tags) => {
          if(tagNameT == tags.tagName){
            tagStatus.forEach((status) => {
              if(tags.status == status){
                // Push no data layer com as informações de retorno da API
                pushDl(EVENT_TO_IGNORE, tags.id, tags.tagName, tags.status, tags.executionTime);
              }
            });
          }
        });
      });
    }
  }
});

// Chame data.gtmOnSuccess depois que a tag for concluída.
data.gtmOnSuccess();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_event_metadata",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "newDataLayer.push"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "_ga"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://script.google.com/a/macros/gruposbf.com.br/s/AKfycbyf93mSuredGdIkSQ5-W6xqhuZFLZKIXfR3QRhpId8jQhyp-JILOPTmiG2-ZV4-P_yDwQ/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 09/01/2026, 17:29:23


