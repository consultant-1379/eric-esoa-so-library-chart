# SO Library Chart

This repo contains helm template functions and templated kubernetes snippets that can be reused across microservice helm charts.

## Using this chart in your microservice

1. Update the apiVersion in your Chart.yaml to version v2
2. Add a dependencies section to your Chart.yaml
   1. name: eric-esoa-so-library-chart
   2. repository: https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm
   3. version: Check the version in Chart.yaml in this repository for the latest version.
   3. execute `helm dependency build` to get the library chart

```yaml

apiVersion: v2
name: eric-so-my-service
version: 0.0.5-1
dependencies:
- name: eric-esoa-so-library-chart
  repository: https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm
  version: <insert version here>

```

## Coding conventions

### Public & Private functions

There is no concept of public/private functions in Helm templating.
All functions are available to application charts to be used.
For this reason there is a naming convention to distinguish public from private.

Private functions are functions which should only be called by other functions in the library chart.
To distinguish them from public functions they have underscore '_' after 'eric-esoa-so-library-chart.' in the name

For example:

```
{{- define "eric-esoa-so-library-chart._value-jdbc-driver" -}}
```

Is a private function to determine the value for the JDBC driver class. It is only used in the `ssl-parameters` function

## Testing

A library chart is not installable by itself, an application chart is required to use the library chart.
This repository contains a test application chart in the `test-charts` folder.
This test application chart must be used to verify the functions in the library chart.
All values must be in the values.yaml as it is not possible to pass in values in CI.

In CI the test application chart is rendered using `helm install --dry-run` to verify the functions and **ensure 
backwards compatibility**

## Contributing

- **All changes to the library chart must be backwards compatible.**
  - This is because [template functions are global](https://helm.sh/docs/chart_template_guide/named_templates/) so if there are duplicates, the last one loaded is used.
  - There will be duplicates since the library chart will be used in multiple microservices which are all dependents of the ESOA integration chart.


- When adding, removing or changing the API of a template function, i.e. the Helm values:
  - If a Helm value is being renamed then the original value should be checked first, if it is not present the new value should be used.
  - Helm values must have sensible defaults.
  - When changing the API, the old value must be marked as deprecated in the function documentation.
  - The deprecated value must also be included in the commit message.
    - This will help with removing the deprecated value in the future.

- When changing the implementation of a template function:
  - A new function must be created with a version identifier in the function name.
  - This is the recommended approach from the [helm documentation](https://helm.sh/docs/chart_template_guide/named_templates/)
  - e.g. if the original function name is "eric-esoa-so-library-chart.sip-tls-volume-mounts"
  - the new function name must be "eric-esoa-so-library-chart.sip-tls-volume-mounts.v1"
  - All subsequent implementation changes to the function must increment the version, v2, v3, etc.


- Bring up change with the Design Lead of your team to add as an agenda item to be discussed in the Design Lead forum

- Code changes can be submitted for review to the `ESOA/ESOA-Parent/com.ericsson.bos.so/eric-esoa-so-library-chart` project at [Gerrit Central](https://gerrit.ericsson.se/).

  `git push origin HEAD:refs/for/master`

- Once a Helm value is no longer used by any application chart then it can be removed. This will need to be a separate exercise which is undertaken periodically. The process can be found [here](#deprecated-helm-value-removal)

## What templates are in this repo?

The templates in this repo can be found [here](charts/eric-esoa-so-library-chart/templates)

Descriptions of each of the templates are kept with them.

Helm functions are leveraged extensively in the templates, documentation for which can be found on the [Helm site](https://helm.sh/docs/chart_template_guide/function_list/)

## Deprecated Helm value removal

All changes to the library chart must be backwards compatible, however we can't keep deprecated values forever.
Once a value is deprecated at some point in the future it should no longer be in use and should be removed.
This is a manual process as the usages of the library chart values need to be checked.

* Pick a specific deprecated value.
  * for example: `serverCertSecret.name`
* Find out when it was deprecated, and what the next released version was.
  * This will require analysis of the code and git log output.
* Download the latest eric-esoa-so and eric-esoa-platform integration charts.
  * example:
    * `curl -u <ericsson-id> -O https://arm.sero.gic.ericsson.se/artifactory/proj-so-gs-all-helm-local/eric-esoa-so/eric-esoa-so-<version>.tgz`
  * example:
    * `curl -u <ericsson-id> -O https://arm.seli.gic.ericsson.se/artifactory/proj-eric-bos-esoa-drop-helm-local/eric-esoa-platform/eric-esoa-platform-<version>.tgz`
* tar -xvf on the charts
  * example:
    * `tar -xvf eric-esoa-so-<version>.tgz`
* grep for library chart and include 1 or 2 lines either side to see version.
  * example:
    * `grep -r -A 2 -B 2 --include Chart.yaml --include requirements.yaml  "eric-esoa-so-library-chart`
* Make sure all microservices are on a newer version of the library chart then when the value was deprecated.
* Check if the deprecated value is being used.
  * example:
    * `grep -r -A 2 -B 2  "serverCertSecret"`

* If it is not being used and the value has a default then the deprecated value can be removed.
* If the value is specified in a microservice then it needs to be updated to move away from the old value before it can be removed