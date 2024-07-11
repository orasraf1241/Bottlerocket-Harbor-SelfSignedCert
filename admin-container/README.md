# Regaining Access to Bottlerocket with a Kubernetes Pod
This guide outlines how to create a Pod in Kubernetes to regain access to a Bottlerocket node by enabling the admin or control container.

## Requirements:

Existing Kubernetes cluster with access to the Bottlerocket node.
kubectl command-line tool configured for your Kubernetes cluster.

## Steps:

### Create the regain-access DaemonSet:

   This DaemonSet mounts the apiclient binary and the API socket with the required SELinux labels, allowing you to interact with the Bottlerocket API.
 
```
# regain-access.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: regain-access
spec:
  selector:
    matchLabels:
      app: regain-access  # Label to identify Pods belonging to this DaemonSet
  template:
    metadata:
      labels:
        app: regain-access  # Matches the selector label
    spec:
      containers:
      - name: regain-access
        image: fedora
        command: ["sleep", "infinity"]  # Keeps container running
        volumeMounts:
        - mountPath: /usr/bin/apiclient
          name: apiclient
          readOnly: true
        - mountPath: /run/api.sock
          name: apiserver-socket
        securityContext:
          seLinuxOptions:
            level: s0
            role: system_r
            type: control_t
            user: system_u
      volumes:
        - name: apiclient
          hostPath:
            path: /usr/bin/apiclient
            type: File
        - name: apiserver-socket
          hostPath:
            path: /run/api.sock
            type: Socket
```



### Create the DaemonSet:

Use kubectl to create the DaemonSet from the YAML file:

```
kubectl create -f regain-access.yaml
```





### Identify and Exec into the Pod:

- Run this command to list the Pods.
```
kubectl get pods -o wide
```
- Find the Pod named regain-access running on your target Bottlerocket node (by IP or hostname).
- Exec into the Pod using: 
```
kubectl exec -it <pod_name> -- bash 
```




### Enable Admin or Control Container:

  Use the apiclient binary within the Pod to enable the desired container:

* Enable Admin Container:

```
apiclient set host-containers.admin.enabled=true
```
* Enable Control Container:

```
apiclient set host-containers.control.enabled=true
```



### Connect to the admin container: 
Once you've enabled the admin container, you can directly connect to it using the following command within the regain-access Pod shell:
 ```
 apiclient exec admin bash
 ```
This will grant you a privileged shell within the admin container, allowing you to troubleshoot your Bottlerocket node.





### Clean Up (Exit, Close Access, and Delete Pod):

After you've finished working within the container, it's crucial to clean up the environment to maintain security and resource efficiency. Here's a breakdown of the steps:

 Close Access (Optional but Highly Recommended):
 
 
```
# If you enabled the admin container, it's strongly recommended to disable it before exiting the Pod shell. This ensures you
#don't leave an open, privileged access point on your Bottlerocket node:

apiclient set host-containers.admin.enabled=false
apiclient set host-containers.control.enabled=false
exit

#Delete the regain-access Pod:
kubectl delete pod regain-access
```


