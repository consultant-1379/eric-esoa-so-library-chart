{{/*
Get the image path for the EDB JDBC Driver image.

global.edbDriverImage values take precedence over eric-product-info.yaml & global.registry values.

*/}}
{{- define "eric-esoa-so-library-chart.edbDriverImagePath" -}}
{{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}

{{- $productInfoRegistryUrl := index $productInfo "images" "mainImage" "registry" -}}
{{- $globalRegistryUrl := default $productInfoRegistryUrl .Values.global.registry.url -}}
{{- $registryUrl := default $globalRegistryUrl .Values.global.edbDriverImage.url -}}

{{- $productInfoRepoPath := index $productInfo "images" "mainImage" "repoPath" -}}
{{- $globalRegistryRepoPath := default $productInfoRepoPath .Values.global.registry.repoPath -}}
{{- $repoPath := default $globalRegistryRepoPath .Values.global.edbDriverImage.repoPath -}}

{{- $name := .Values.global.edbDriverImage.name | required "EDB Driver image name is required when the database vendor is EDB" -}}
{{- $tag := .Values.global.edbDriverImage.tag | required "EDB Driver image tag is required when the database vendor is EDB" -}}
{{- if $repoPath -}}
    {{- $repoPath = printf "%s/" $repoPath -}}
{{- end -}}
{{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Prepare any ssl parameters for the jdbc url

The optional helm values for this template are:
1.  .Values.database.jdbcUrl - jdbc url specified by the user, no default value
2.  .Values.database.generic - a map of key values pairs which will be added to the jdbc url as parameters
3.  .Values.database.sslMode - replacement for sslEnabled, this determines what the sslMode is, require, verify-ca, verify-full. Can also be disabled, defaults to "verify-ca"
4.  .Values.database.serverCertSecret - the name of the secret containing the server cert, defaults to "edb-server-cert"
5.  .Values.database.pathToServerCert - the mounted folder path for the server cert secret, defaults to "/mnt/ssl/server/"
6.  .Values.database.rootCertPath - the path to the server cert within the secret, defaults to "root.crt"
7.  .Values.database.clientCertSecret - the name of the secret containing the client cert and key, defaults to "<microservice-name>-edb-client-cert"
8.  .Values.database.pathToClientCert - the mounted folder path for the client cert secret, defaults to "/mnt/ssl/client/"
9.  .Values.database.clientCertRoot - the key of the client cert data item in the secret, defaults to "tls.crt"
10. .Values.database.clientCertPath - the path to the client cert within the secret, defaults to "tls.crt"
11. .Values.database.clientCertKey - the key of the client key data item in the secret, defaults to "tls.key"
12. .Values.database.clientKeyPath - the path to the client key within the secret, defaults to "tls.key"
13. .Values.database.connectionTimeout - the value for the connectTimeout parameter of the jdbc url

*/}}
{{- define "eric-esoa-so-library-chart.sslParameters" -}}
  {{- if .Values.database.schemaName -}}
    {{- print "&" -}}
  {{- else -}}
    {{- printf "?" -}}
  {{- end -}}
  {{- include "eric-esoa-so-library-chart._get-generic-jdbc-url-parameters" . -}}
  {{- if .Values.database.connectionTimeout -}}
    {{- printf "connectTimeout=%s&" ( toString .Values.database.connectionTimeout ) -}}
  {{- end -}}
  {{- if ( include "eric-esoa-so-library-chart.ssl-enabled" . ) -}}
    {{- $sslMode := ternary "" ( printf "&sslmode=%s" (include "eric-esoa-so-library-chart.ssl-enabled" . )) (empty (include "eric-esoa-so-library-chart.ssl-enabled" .) ) -}}
    {{- $mode := printf "ssl=true%s" $sslMode -}}
    {{- $sslrootcert := printf "&sslrootcert=%s%s" (include "eric-esoa-so-library-chart._value-path-to-server-cert" .) (include "eric-esoa-so-library-chart._value-relative-path-to-ca-crt" .) -}}
    {{- printf "%s%s" $mode $sslrootcert -}}
    {{- if eq "true" ( include "eric-esoa-so-library-chart.is-it-mtls" . ) }}
      {{- if .Values.database.requiresClientCert }}
         {{- $clientCert := printf "&sslcert=%s%s" (include "eric-esoa-so-library-chart._value-path-to-client-cert" . ) ( include "eric-esoa-so-library-chart._value-relative-path-to-client-cert" . ) -}}
         {{- $clientKey := printf "&sslkey=%s%s" (include "eric-esoa-so-library-chart._value-path-to-client-cert" . ) ( include "eric-esoa-so-library-chart._value-relative-path-to-client-key" .) -}}
         {{- printf "%s%s" $clientCert $clientKey -}}
      {{- else }}
        {{- $secret := lookup "v1" "Secret" .Release.Namespace ( include "eric-esoa-so-library-chart._value-client-cert-secret-name" . ) -}}
        {{- $clientCertPresent := not (empty (get $secret.data ( include "eric-esoa-so-library-chart._value-client-cert-secret-item-cert-key" . ))) -}}
        {{- $clientCert := ternary (printf "&sslcert=%s%s" (include "eric-esoa-so-library-chart._value-path-to-client-cert" . ) ( include "eric-esoa-so-library-chart._value-relative-path-to-client-cert" . )) "" $clientCertPresent -}}
        {{- $clientKeyPresent := not (empty (get $secret.data ( include "eric-esoa-so-library-chart._value-client-cert-secret-item-key-key" . ))) -}}
        {{- $clientKey := ternary (printf "&sslkey=%s%s" (include "eric-esoa-so-library-chart._value-path-to-client-cert" . ) ( include "eric-esoa-so-library-chart._value-relative-path-to-client-key" .)) "" $clientKeyPresent -}}
        {{- printf "%s%s" $clientCert $clientKey -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Prepare the jdbc url if specified
*/}}
{{- define "eric-esoa-so-library-chart.jdbcUrl" -}}
{{- printf "%s%s" .Values.database.jdbcUrl (include "eric-esoa-so-library-chart.sslParameters" .) -}}
{{- end -}}

{{/*
Define the volume for the server certificate data from the secret.
If ssl is enabled a volume containing the server certificate is required.

The optional helm values for this template are:
1. .Values.database.sslMode - whether ssl is enabled or not, defaults to "verify-ca"
1. .Values.database.serverCertSecret - the name of the secret containing the database server CA certificate, defaults to "edb-server-cert"
2. .Values.database.rootCertPath - the path is the relative path of the file to map the key to, defaults to "root.crt"
3. .Values.database.serverCertKey - the item name in the secret, defaults to "ca.crt"

When using this function remember to indent the output the correct amount.
Example:

      volumes:
      {{- include "eric-esoa-so-library-chart.edb-server-cert-volume" . | indent 6 }}

*/}}
{{- define "eric-esoa-so-library-chart.edb-server-cert-volume" -}}
{{- if ( include "eric-esoa-so-library-chart.ssl-enabled" . ) }}
- name: server-cert-volume
  secret:
    items:
      - key: {{ include "eric-esoa-so-library-chart._value-server-cert-secret-item-cert-key" . | quote }}
        path: {{ (include "eric-esoa-so-library-chart._value-relative-path-to-ca-crt" .) | quote }}
    secretName: {{ include "eric-esoa-so-library-chart._value-server-cert-secret-name" . | quote }}
{{- end }}
{{- end -}}

{{/*
Define the environment parameter for database connection property.
This function supports connection property to multiple datasource.

The optional helm values for this template are:
1. database.connection[0].maxLifetime - This property controls the maximum lifetime of a connection in the pool.
2. database.connection[0].maxPoolSize - This property controls the maximum size that the pool is allowed to reach,
                                        including both idle and in-use connections.
3. database.connection[0].idleTimeout - This property controls the maximum amount of time that a connection is
                                        allowed to sit idle in the pool.
4. database.connection[0].minIdle - This property controls the minimum number of idle connections that HikariCP
                                    tries to maintain in the pool.

When using this function remember to indent the output the correct amount.
Always provide the global as well as local parameter as defined in the values.yaml file example given below.
If any database connection optional property and is not required then do not provide the key in the values file for the
local parameters. The function would skip the parameter if it is not defined in the values file.
For Example if minIdle for database connection is not required for any datasource then don't define below parameters
database.connection[0].minIdle
Good practice is the define the global property if local property is defined.


Example:

deployments.yaml
      env:
      {{- include "eric-esoa-so-library-chart.database-connection-property" .| indent 8 }}

values.yaml
global:
  database:
    connection:
      maxLifetime: 30
      maxPoolSize: 20
      idleTimeout: 20000
      minIdle: 1

database:
  connection:
  - maxLifetime: 200
    maxPoolSize: 200
    idleTimeout: 30000
    minIdle: 2
  - maxLifetime: 400
    maxPoolSize: 200
    idleTimeout: 40000
    minIdle: 2

# The properties should be used in application.yaml as below

spring:
  datasource:
    enginedb:
      maximum-pool-size: ${DB_MAX_POOL_SIZE_CONNECTION_0:200}
      max-lifetime: ${DB_MAX_LIFETIME_CONNECTION_0:840000}
      minimum-idle: ${DB_MIN_IDLE_CONNECTION_0:2}
      idle-timeout: ${DB_IDLE_TIMEOUT_CONNECTION_0:20000}
    camunda:
      maximum-pool-size: ${DB_MAX_POOL_SIZE_CONNECTION_1:200}
      max-lifetime: ${DB_MAX_LIFETIME_CONNECTION_1:840000}
      minimum-idle: ${DB_MIN_IDLE_CONNECTION_1:2}
      idle-timeout: ${DB_IDLE_TIMEOUT_CONNECTION_1:20000}

# Some error scenario

#Defining local property with nil value and not defining global property
Example:
values.yaml
global:
  database:
    connection:
      maxLifetime: 30
      maxPoolSize: 20
      idleTimeout: 20000

database:
  connection:
  - maxLifetime: 200
    maxPoolSize: 200
    idleTimeout: 30000
    minIdle:

*/}}
{{- define "eric-esoa-so-library-chart.database-connection-property" -}}
{{ if and (hasKey .Values "database") (hasKey .Values.database "connection") }}
{{- range $i, $value := .Values.database.connection -}}
{{- if hasKey ($value) "maxLifetime" }}
- name: DB_MAX_LIFETIME_CONNECTION_{{ $i }}
{{- if ne $value.maxLifetime nil }}
  value: {{ $value.maxLifetime | quote }}
{{- else }}
  value: {{ $.Values.global.database.connection.maxLifetime | quote }}
{{- end }}
{{- end }}
{{- if hasKey ($value) "maxPoolSize" }}
- name: DB_MAX_POOL_SIZE_CONNECTION_{{ $i }}
{{- if ne $value.maxPoolSize nil }}
  value: {{ $value.maxPoolSize | quote }}
{{- else }}
  value: {{ $.Values.global.database.connection.maxPoolSize | quote }}
{{- end }}
{{- end }}
{{- if hasKey ($value) "idleTimeout" }}
- name: DB_IDLE_TIMEOUT_CONNECTION_{{ $i }}
{{- if ne $value.idleTimeout nil }}
  value: {{ $value.idleTimeout | quote }}
{{- else }}
  value: {{ $.Values.global.database.connection.idleTimeout | quote }}
{{- end }}
{{- end }}
{{- if hasKey ($value) "minIdle" }}
- name: DB_MIN_IDLE_CONNECTION_{{ $i }}
{{- if ne $value.minIdle nil }}
  value: {{ $value.minIdle | quote }}
{{- else }}
  value: {{ $.Values.global.database.connection.minIdle | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Define the volume for the client certificate data from the secret.

The optional helm values for this template are:
1. .Values.database.clientCertKey - the key in the secret of the client key, defaults to "tls.key"
2. .Values.database.clientCertRoot - the key in the secret of the client cert, defaults to "tls.crt"
3. .Values.database.clientCertPath - the relative path to the client cert in the secret, defaults to "tls.crt"
4. .Values.database.clientKeyPath - the relative path to the client key in the secret, defaults to "tls.key"
5. .Values.database.clientCertSecret - the name of the client cert secret, defaults to "<microservice-name>-edb-client-cert"

When using this function remember to indent the output the correct amount.
Example:

      volumes:
      {{- include "eric-esoa-so-library-chart.edb-client-cert-volume" . | indent 6 }}


*/}}
{{- define "eric-esoa-so-library-chart.edb-client-cert-volume" -}}
{{- if eq "true" ( include "eric-esoa-so-library-chart.is-it-mtls" . ) }}
- name: client-cert-volume
  secret:
    items:
    - key: {{ include "eric-esoa-so-library-chart._value-client-cert-secret-item-cert-key" . | quote }}
      path: {{ include "eric-esoa-so-library-chart._value-relative-path-to-client-cert" . | quote }}
    - key: {{ include "eric-esoa-so-library-chart._value-client-cert-secret-item-key-key" . | quote }}
      path: {{ include "eric-esoa-so-library-chart._value-relative-path-to-client-key" . | quote }}
    secretName: {{ include "eric-esoa-so-library-chart._value-client-cert-secret-name" . | quote }}
{{- end -}}
{{- end -}}

{{/*
Define the volume mount for the client certificate

The optional helm values for this template:
1. .Values.database.clientCertSecret - the name of the secret containing the client cert and key, defaults to "<microservice-name>-edb-client-cert"
2. .Values.database.pathToClientCert - the path to the client cert and key in the pod filesystem, defaults to "/mnt/ssl/client/"

When using this function remember to indent the output the correct amount.
Example:

          volumeMounts:
          {{- include "eric-esoa-so-library-chart.edb-client-cert-volume-mount" . | indent 10 }}

*/}}
{{- define "eric-esoa-so-library-chart.edb-client-cert-volume-mount" -}}
{{- if eq "true" ( include "eric-esoa-so-library-chart.is-it-mtls" . ) }}
- name: client-cert-volume
  mountPath: {{ include "eric-esoa-so-library-chart._value-path-to-client-cert" . | quote }}
{{- end }}
{{- end -}}

{{/*
Determine if the communication is going to be mTLS.
The presence/absence of the secret containing the client certificate will determine this. Alternatively, in deployments
where a client secret is not be predeployed then the value '.Values.database.requiresClientCert' can be set
to enable mtls towards the database. 


The optional helm values for this template are:
1. Values.database.clientCertSecret - the name of the secret containing the client cert and key, defaults to "<microservice-name>-edb-client-cert"
2. Values.database.requiresClientCert - flag indicating that the database requires a client cert.

*/}}
{{- define "eric-esoa-so-library-chart.is-it-mtls" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace ( include "eric-esoa-so-library-chart._value-client-cert-secret-name" . ) -}}
{{- or (not (empty (get $secret "data"))) (default "false" .Values.database.requiresClientCert) -}}
{{- end -}}

{{/*
Define the volume mount for the server certificate

The required helm values for this template:
1. .Values.database.sslMode - whether ssl is enabled or not, defaults to "verify-ca"
2. .Values.database.pathToServerCert - the path to mount the volume to in the file system, defaults to "/mnt/ssl/server/"

When using this function remember to indent the output the correct amount.
Example:

          volumeMounts:
          {{- include "eric-esoa-so-library-chart.edb-server-cert-volume-mount" . | indent 10 }}

*/}}
{{- define "eric-esoa-so-library-chart.edb-server-cert-volume-mount" -}}
{{- if ( include "eric-esoa-so-library-chart.ssl-enabled" . ) }}
- name: server-cert-volume
  mountPath: {{ include "eric-esoa-so-library-chart._value-path-to-server-cert" . | quote }}
{{- end }}
{{- end -}}

{{/*
Define the environment variables for the database

The required helm values for this template:
1. .Values.database.secret - the name of the secret which contains the database credentials
2. .Values.database.userkey - the key of the item in the secret which contains the application user username
3. .Values.database.passwdkey - the key of the item in the secret which contains the application user password
The optional helm values for this template:
1. .Values.database.host - the hostname of the database instance
2. .Values.database.port - the port of the database instance
3. .Values.database.dbName - the name of the database
4. .Values.database.jdbcUrl - the jdbc url, if not specified is built from host, port, dbName, sslParameters
5. .Values.database.vendor - the vendor of the database, defaults to postgresql but will be set to edb in production
6. .Values.database.driverPath - the path in the pod to store the EDB JDBC , defaults to "/tmp/edb/driver"
*/}}
{{- define "eric-esoa-so-library-chart.db-env-variables" -}}
- name: DB_HOST
  value: {{ .Values.database.host | quote }}
- name: DB_PORT
  value: {{ .Values.database.port | quote }}
- name: DB_NAME
  value: {{ .Values.database.dbName | quote }}
- name: SCHEMA_NAME
  value: {{ default (include "eric-esoa-so-library-chart.name" . | replace "-" "_") .Values.database.schemaName | quote }}
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.secret }}
      key: {{ .Values.database.userkey }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.secret }}
      key: {{ .Values.database.passwdkey }}
- name: DB_VENDOR
  value: {{ include "eric-esoa-so-library-chart.value-db-vendor" . | quote }}
{{- if .Values.database.jdbcUrl }}
- name: JDBC_URL
  value: {{ include "eric-esoa-so-library-chart.jdbcUrl" . | quote }}
{{- end }}
- name: DB_DRIVER
  value: {{ include "eric-esoa-so-library-chart._value-jdbc-driver" . | quote }}
{{- if eq "edb" ( include "eric-esoa-so-library-chart.value-db-vendor" . ) }}
- name: LOADER_PATH
  value: {{ include "eric-esoa-so-library-chart._value-path-to-edb-driver" . | quote }}
{{- end }}
- name: SSL_PARAMETERS
  value: {{ include "eric-esoa-so-library-chart.sslParameters" . | quote }}
{{- end -}}

{{/*
Define the init container which will load the EDB JDBC driver into the pod filesystem

The optional helm values for this template:
1. .Values.database.vendor - the vendor of the database instance, can be postgresql or edb. Defaults to "postgresql"
2. .Values.database.driverPath - the path in the pod to store the EDB JDBC driver, defaults to "/tmp/edb/driver"
*/}}
{{- define "eric-esoa-so-library-chart.edb-driver-init-container" -}}
{{- if eq (  include "eric-esoa-so-library-chart.value-db-vendor" . ) "edb" }}
- name: {{ .Chart.Name }}-load-edb-driver
  image: {{ template "eric-esoa-so-library-chart.edbDriverImagePath" . }}
  env:
    - name: EDB_DRIVER_PATH
      value: {{ include "eric-esoa-so-library-chart._value-path-to-edb-driver" . | quote }}
  volumeMounts:
{{ include "eric-esoa-so-library-chart.edb-driver-volume-mount" . | indent 2 }}
{{- end -}}
{{- end -}}

{{/*
Define the volume which the EDB JDBC driver will be mounted into

The required helm values for this template:
1. .Values.database.vendor - the vendor of the database instance, can be postgresql or edb. Defaults to "postgresql"
*/}}
{{- define "eric-esoa-so-library-chart.edb-driver-volume" -}}
{{- if eq ( include "eric-esoa-so-library-chart.value-db-vendor" . ) "edb" }}
- name: edb-driver-volume
  emptyDir:
    medium: ""
    sizeLimit: 5Mi
{{- end }}
{{- end -}}

{{/*
Define the volume mount which the main and init container will use for the EDB JDBC Driver

The optional helm values for this template:
1. .Values.database.driverPath - the path in the pod to store the EDB JDBC driver, defaults to "/tmp/edb/driver"
*/}}
{{- define "eric-esoa-so-library-chart.edb-driver-volume-mount" -}}
{{- if eq ( include "eric-esoa-so-library-chart.value-db-vendor" . ) "edb" -}}
- name: edb-driver-volume
  mountPath: {{ include "eric-esoa-so-library-chart._value-path-to-edb-driver" . | quote }}
{{- end -}}
{{- end -}}

{{/*
Determine if SSL communication should be enabled or not.
If enabled the sslmode is returned from this helper function.

Note:
When using this function in an if block don't check that the result eq "true".
i.e. don't do this:
{{- if eq (include "eric-esoa-so-library-chart.ssl-enabled" .) "true" -}}
do this instead:
{{- if (include "eric-esoa-so-library-chart.ssl-enabled" .) -}}

The If check in helpers follows the truthy concept, https://helm.sh/docs/chart_template_guide/control_structures/#ifelse
- Empty string is false.
- Any other string is true.


The optional helm values for this template:
1. .Values.database.sslMode - can have the value disabled, require, verify-ca or verify-full. Defaults to "verify-ca"
*/}}
{{- define "eric-esoa-so-library-chart.ssl-enabled" -}}
{{- $sslEnabled := true -}}
{{- if hasKey .Values.database "sslEnabled" -}}
  {{- $sslEnabled = .Values.database.sslEnabled -}}
{{- end -}}
{{- if .Values.database.sslMode -}}
  {{- if (or (contains "disable" (lower .Values.database.sslMode)) (empty .Values.database.sslMode)) -}}
    {{- printf "" -}}
  {{- else -}}
    {{- $sslMode := lower .Values.database.sslMode -}}
    {{- if (has $sslMode (tuple "allow" "prefer" "require" "verify-ca" "verify-full")) -}}
      {{- $sslMode -}}
    {{- else -}}
      {{- fail (printf "%s is not a valid sslMode" $sslMode) -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- ternary "verify-ca" "" $sslEnabled -}}
{{- end -}}
{{- end -}}

{{/*
Get DB Vendor value.
default is postgresql
*/}}
{{- define "eric-esoa-so-library-chart.value-db-vendor" -}}
{{- if .Values.database.vendor -}}
  {{- $vendor := .Values.database.vendor | lower -}}
  {{- if not ( has $vendor ( tuple "edb" "postgresql" )) -}}
    {{- fail (printf "Database vendor is not valid/supported, %s" $vendor) -}}
  {{- end -}}
  {{- $vendor -}}
{{- else -}}
  postgresql
{{- end -}}
{{- end -}}

{{/*
Get the value for the path to the server cert.
This is an optional value with a default.
*/}}
{{- define "eric-esoa-so-library-chart._value-path-to-server-cert" -}}
{{- if .Values.database -}}
  {{- default "/mnt/ssl/server/" .Values.database.pathToServerCert -}}
{{- end -}}
{{- end -}}

{{/*
Get the value for the path to the client cert and key
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-path-to-client-cert" -}}
{{- default "/mnt/ssl/client/" .Values.database.pathToClientCert -}}
{{- end -}}

{{/*
Get the value for the path to the EDB JDBC Driver
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-path-to-edb-driver" -}}
{{- default "/tmp/edb/driver" .Values.database.driverPath -}}
{{- end -}}

{{/*
Get the value for the relative path to the CA root crt in the pod filesystem
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-relative-path-to-ca-crt" -}}
{{- default "root.crt" .Values.database.rootCertPath -}}
{{- end -}}

{{/*
Determine the JDBC Driver from the DB Vendor
*/}}
{{- define "eric-esoa-so-library-chart._value-jdbc-driver" -}}
{{- $jdbcDriver := "org.postgresql.Driver" -}}
{{- if eq "edb" ( include "eric-esoa-so-library-chart.value-db-vendor" . ) -}}
  {{- $jdbcDriver = "com.edb.Driver" -}}
{{- end -}}
{{- printf "%s" $jdbcDriver -}}
{{- end -}}

{{/*
Get the value for the name of the server certificate secret
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-server-cert-secret-name" -}}
{{- $serverCertSecretName := "edb-server-cert" -}}
{{- if .Values.global.database -}}
  {{- if .Values.global.database.serverCertSecret -}}
    {{- $serverCertSecretName = .Values.global.database.serverCertSecret -}}
  {{- end -}}
{{- end -}}
{{- if .Values.database -}}
  {{- if .Values.database.serverCertSecret -}}
      {{- $serverCertSecretName = .Values.database.serverCertSecret -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $serverCertSecretName -}}
{{- end -}}

{{/*
Get the value for the name of the client certificate secret
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-client-cert-secret-name" -}}
{{- default (printf "%s-edb-client-cert" (include "eric-esoa-so-library-chart.name" . ) ) .Values.database.clientCertSecret -}}
{{- end -}}

{{/*
Get the value for the relative path to the Client certificate in the secret
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-relative-path-to-client-cert" -}}
{{ default "tls.crt" .Values.database.clientCertPath -}}
{{- end -}}

{{/*
Get the value for the relative path to the Client Key in the secret
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-relative-path-to-client-key" -}}
{{ default "tls.key" .Values.database.clientKeyPath -}}
{{- end -}}

{{/*
Get the value for the server cert secret cert item key
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-server-cert-secret-item-cert-key" -}}
{{- $serverCertKey := "ca.crt" -}}
{{- if .Values.database -}}
  {{- if .Values.database.serverCertKey -}}
    {{- $serverCertKey = .Values.database.serverCertKey -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $serverCertKey -}}
{{- end }}

{{/*
Get the value for the client cert secret cert item key
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-client-cert-secret-item-cert-key" -}}
{{- $clientCertKey := "tls.crt" -}}
{{- if .Values.database -}}
  {{- if .Values.database.clientCertRoot -}}
    {{- $clientCertKey = default "tls.crt" .Values.database.clientCertRoot -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $clientCertKey -}}
{{- end }}

{{/*
Get the value for the client cert secret key item key
This is an optional value with a default
*/}}
{{- define "eric-esoa-so-library-chart._value-client-cert-secret-item-key-key" -}}
{{- $clientKeyKey := "tls.key" -}}
{{- if .Values.database -}}
  {{- if .Values.database.clientCertKey -}}
    {{- $clientKeyKey = default "tls.key" .Values.database.clientCertKey -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $clientKeyKey -}}
{{- end }}

{{/*
This function enables the addition of any parameters to the jdbc url
It take the map under .Values.database.generic, and prints it in the format key=value&
*/}}
{{- define "eric-esoa-so-library-chart._get-generic-jdbc-url-parameters" -}}
{{- range $key, $val := .Values.database.generic -}}
  {{- $key -}}={{- $val -}}&
{{- end -}}
{{- end -}}