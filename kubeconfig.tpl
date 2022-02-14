clusters:
- cluster:
    certificate-authority-data: $SA_CA_CRT
    server: $APISERVER
  name: my-cluster
users:
- name: my-user
  user:
    as-user-extra: {}
    client-key-data: $SA_CA_CRT
    token: $SA_TOKEN
contexts:
- context:
    cluster: my-cluster
    namespace: default
    user: my-user
  name: my-context
current-context: my-context
