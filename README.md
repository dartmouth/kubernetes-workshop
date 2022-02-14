# Kubernetes Workshop

```text
Introduction to Container Automation and Orchestration with Kubernetes
Instructors: Jonathan Crossett / Elijah Gagne - Research Computing
Date/time: 2/16 @1-2:30p
Format: Zoom/online

After having deployed a few containers with Docker, look into Kubernetes, an open-source container-orchestration system for automating computer application deployment, scaling, and management. It was originally designed by Google. Research Computing is offering this hands-on workshop as an introduction to Kubernetes. In this introduction, you'll learn the fundamentals of Kubernetes.  Topics will include Pods, Deployments, Services, Persistent Volumes, Persistent Volume Claims, and more.

Please install minikube (https://minikube.sigs.k8s.io/docs/start/) before the workshop if you plan to follow along.
```

* Kubernetes Overview
  * "The car, not the destination"
* Working with `minikube`
    ```shell
    minikube start --cni=calico # Create cluster
    minikube stop               # Stop cluster
    minikube start              # Start cluster
    minikube status             # Check cluster status
    minikube node add           # Add node
    minikube ip                 # Get IP address for primary node
    minikube ip -n minikube-m02 # Get IP address for specific node
    # minikube delete             # Delete cluster
    ```
* CLI
  * Get Client and Kubernetes API Server version
    ```shell
    kubectl version
    ```
  * Default kubectl config:
    ```shell
    cat $HOME/.kube/config
    ```
  * kubeconfig (ENV, flag, context)
    ```shell
    kubectl config get-contexts                # Get current contexts
    kubectl config use-context minikube        # Set the context to `minikube`
    # kubectl --kubeconfig=$HOME/.kube/mykubeconfig  # Specify a non-default configuration file
    # export KUBECONFIG=$HOME/.kube/mykubeconfig
    ```
  * CLI Help
    ```shell
    kubectl               # Get available commands
    kubectl options       # Global options
    kubectl get -h        # Command specific help
    kubectl api-resources # Get resources
    ```
  * Using curl
    ```shell
    APISERVER="https://$(minikube ip):8443"
    TOKEN=$(kubectl -n kube-system get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
    echo $TOKEN
    curl -k -X GET $APISERVER/version -H "Authorization: Bearer $TOKEN" 
    ```
* Nodes (https://kubernetes.io/docs/concepts/overview/components/)
  * Interacting with nodes
    ```shell
    kubectl get node                                       # Get list of nodes and their status
    kubectl cordon minikube-m02                            # Prevent node from getting any new workload
    kubectl get node
    kubectl drain minikube-m02 --ignore-daemonsets --force # Evict all workloads from a node and cordon node
    kubectl uncordon minikube-m02                          # Allow node to get workload
    kubectl get node
    kubectl cordon minikube                                # Cordon control-plane node for demos
    ```
  * Node components
    * kubelet (containers, logs)
    * kube-proxy (service ip routing)
    * Container runtime
  * Controlplane
    * API Server
    * Controller Manager
    * Scheduler
    * etcd
  * Addons
    * coredns
* Container Runtime Interface (CRI)
  * Runtimes (https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
    * containerd
    * CRI-O
    * Docker Engine
  * Determine CRI
    ```shell
    kubectl get node -o wide
    ```
* Container Network Interface (CNI) (https://kubernetes.io/docs/concepts/cluster-administration/networking/)
    ```shell
    kubectl -n kube-system get pod | grep calico
    kubectl cluster-info dump | grep -m 1 service-cluster-ip-range
    kubectl cluster-info dump | grep -m 1 cluster-cidr
    ```
* Container Storage Interface (CSI) (https://kubernetes.io/blog/2019/01/15/container-storage-interface-ga/)
    ```shell
    kubectl get storageclass
    kubectl -n kube-system get pod | grep storage-provisioner
    ```
* PersistentVolume/PersistentVolumeClaim
  * DOCS: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
  * Create PersistentVolumeClaim
    ```shell
    kubectl apply -f pvc.yml
    ```
  * Inspect PV/PVC
    ```shell
    kubectl get pvc
    kubectl get pv
    kubectl get pv -o yaml  # Using hostPath, not the same on each host
    ```
* Pod
  * Create Pod
    ```shell
    kubectl apply -f pod-with-pvc.yml
    ```
  * Inspect pod
    ```shell
    kubectl get pod pod-test -o wide
    kubectl describe pod pod-test
    kubectl logs --tail 10 -f pod-test
    ```
  * Interact with pod
    ```shell
    kubectl exec -ti pod-test -- sh  # Execute command in pod
      echo "<h1>Hello from the volume</h1>" > /usr/share/nginx/html/volume/index.html
      echo "<h1>Hello from local storage</h1>" > /usr/share/nginx/html/index.html
      exit
    IP=$(kubectl get pod pod-test -o jsonpath='{.status.podIP}')
    curl $IP/volume/                  # Can't access the cluster IP range outside the kubernetes cluster
    minikube ssh curl $IP/volume/
    minikube ssh curl $IP             # Can access the cluster IP inside the cluster
    kubectl delete pod pod-test
    kubectl apply -f pod-with-pvc.yml # Recreate pod
    kubectl get pod -o wide           # IP Address changes
    IP=$(kubectl get pod pod-test -o jsonpath='{.status.podIP}')
    minikube ssh curl $IP/volume/     # Remains the same
    minikube ssh curl $IP             # Reverted back to the original index.html
    ```
* Service (https://kubernetes.io/docs/concepts/services-networking/service/)
  * Create ClusterIP service
    ```shell
    kubectl apply -f svc-clusterip.yml
    ```
  * Inspect ClusterIP Service
    ```shell
    kubectl get svc service-test -o wide
    IP=$(kubectl get svc service-test -o jsonpath='{.spec.clusterIP}')
    minikube ssh curl $IP/volume/
    ```
  * Change to NodePort Service
    ```shell
    kubectl apply -f svc-nodeport.yml
    ```
  * Inspect NodePort Service
    ```shell
    kubectl get svc service-test -o wide
    minikube ssh curl $IP/volume/
    PORT=$(kubectl get svc service-test -o jsonpath='{.spec.ports[0].nodePort}')
    echo $PORT
    curl $(minikube ip):$PORT/volume/
    ```
  * Cleanup service/pod
    ```shell
    kubectl delete pod pod-test
    kubectl delete svc service-test
    ```
* Deployment (https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
  * Create Deployment
    ```shell
    kubectl apply -f deployment.yml
    ```
  * Interacting with deployment
    ```shell
    kubectl get pod
    kubectl delete pod POD_NAME  # Pod returns
    kubectl scale deployment php-apache --replicas 4 && kubectl get pod --watch
    kubectl get pod
    PORT=$(kubectl get svc php-apache -o jsonpath='{.spec.ports[0].nodePort}')
    curl $(minikube ip):$PORT
    kubectl rollout restart deployment php-apache && kubectl get pod --watch
    kubectl get pod
    kubectl scale deployment php-apache --replicas 1
    kubectl get pod
    ```
* ReplicaSet (https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
    ```shell
    kubectl get replicaset  # Automatically created for us
    ```
* DeamonSet (https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
  * https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/#writing-a-daemonset-spec
* StatefulSet (https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
  * https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#components
* Secrets (https://kubernetes.io/docs/concepts/configuration/secret/)
    ```shell
    kubectl create secret generic -h
    kubectl create secret generic topsecret --from-literal=MYSECRET=watermelon
    kubectl get secret topsecret
    kubectl get secret topsecret -o yaml
    ```
* ConfigMap (https://kubernetes.io/docs/concepts/configuration/configmap/)
    ```shell
    kubectl apply -f configmap.yml
    kubectl get configmap myconfigmap
    kubectl apply -f deployment-with-extras.yml
    kubectl get pod
    curl $(minikube ip):$PORT/env.php
    ```
* Network Policies (https://kubernetes.io/docs/concepts/services-networking/network-policies/)
  * https://kubernetes.io/docs/concepts/services-networking/network-policies/#networkpolicy-resource
* Namespace (https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
  * Manage namespaces
    ```shell
    kubectl get namespaces
    kubectl create namespace mynamespace
    kubectl get namespaces
    ```
  * Create pod in namespace
    ```shell
    kubectl apply -f pod-mynamespace.yml
    ```
  * Accessing namespaces resources
    ```shell
    kubectl api-resources    # Review NAMESPACED column
    kubectl -n mynamespace get pod
    kubectl -n mynamespace get pv  # Non-namespaced resources visible even if providing `-n`
    ```
  * Delete namespace
    ```shell
    kubectl delete namespace mynamespace
    kubectl -n mynamespace get pod
    kubectl get namespace
    ```
* Static Pod (https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
    ```shell
    minikube ssh
    ls /etc/kubernetes/manifests/
    ```
* ServiceAccount (https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
    ```shell
    kubectl apply -f serviceaccount.yml
    kubectl get serviceaccount
    kubectl get secret
    kubectl get serviceaccount
    export SA_SECRET=$(kubectl get serviceaccount admin -o jsonpath='{.secrets[0].name}')
    echo $SA_SECRET
    export SA_CA_CRT=$(kubectl get secret $SA_SECRET -n default -o json | jq -r '.data["ca.crt"]')
    echo $SA_CA_CRT
    export SA_TOKEN=$(kubectl get secret $SA_SECRET -n default -o json | jq -r '.data["token"]' | base64 -d)
    echo $SA_TOKEN
    export APISERVER="https://$(minikube ip):8443"
    echo $APISERVER
    envsubst < kubeconfig.tpl > $HOME/.kube/mykubeconfig
    kubectl --kubeconfig $HOME/.kube/mykubeconfig auth can-i --list
    kubectl delete secret $SA_SECRET
    kubectl --kubeconfig $HOME/.kube/mykubeconfig auth can-i --list
    kubectl get secret
    ```
* Metric Server (https://github.com/kubernetes-sigs/metrics-server)
    ```shell
    minikube addons enable metrics-server  # Enable metrics-server
    kubectl get pod,svc -n kube-system     # Check metrics-server
    kubectl top node                       # Get node usage
    kubectl top pod -A --sort-by=memory    # Get pod usage
    kubectl top pod --containers -A        # Get container usage
    ```
* Horizontal Pod Autoscaler (HPA) (https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
    ```shell
    kubectl apply -f deployment.yml
    kubectl get pod
    kubectl autoscale deployment php-apache --cpu-percent=10 --min=1 --max=10
    kubectl get hpa
    kubectl describe hpa php-apache
    kubectl get pod --watch
    # generate load in another terminal
    kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
    # Wait for load to register (around a minute)
    ```
  * Tune HPA with `--horizontal-pod-autoscaler-*` flags on the Controller Manager (https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)
  * Cleanup
    ```shell
    kubectl delete hpa php-apache
    ```
* Cheatsheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
