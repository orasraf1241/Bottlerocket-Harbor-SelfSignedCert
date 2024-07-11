
# Introduction
This guide provides a comprehensive guide for installing and configuring Harbor on ec2 instances, with a focus on using self-signed certificates. 
Harbor is an open-source container image registry that secures images with role-based access control, scans images for vulnerabilities, and signs images as trusted. 
Bottlerocket Linux-based operating system designed for hosting containers.

By following this guide, you will be able to:

- Install Harbor on Bottlerocket.
- Configure Harbor with self-signed SSL certificates.
- Push and pull container images to and from Harbor.
- Manage certificates in a Kubernetes cluster using both automated and manual methods.

# Install Harbor

1. **Download the Version You Need**
   - Download the desired version from the [Harbor releases page](https://github.com/goharbor/harbor/releases).

2. **Extract the File**
   - Extract the downloaded file using:
     ```sh
     tar -xzvf FILE_NAME
     ```

3. **Create SSL Certificates**
   - Use the `ssl.sh` script to create SSL certificates. Inject the domain name of your Harbor registry into the script.

```
[ec2-user@ip-10-0-162-134 cert]$ ./certs-script/ssl.sh 
Enter your desired domain name: harbor-test.com
```
### 4. **Configure Harbor**
   - Harbor's configuration is managed through the `harbor.yml` file.
   - Rename the template configuration file:
     ```sh
     mv harbor.yml.tmp harbor.yml
     ```
   - Open `harbor.yml` in a text editor and make the following changes(if you want to make more customization ):
     - Set the `hostname:` field to match the domain name used in your SSL certificates.
     - Update the paths to the certificate and private key files:
       ```yaml
       hostname: harbor-test.com
       certificate: /home/ec2-user/harbor/cert/harbor-test.com.crt
       private_key: /home/ec2-user/harbor/cert/harbor-test.com.key
       ```

### 5. **Install Docker Compose (if not installed)**
   - Docker Compose is required to run Harbor. If you don't have Docker Compose installed, follow [this guide](https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/) to install it.

## Pushing and Pulling Images from Harbor

### Pushing an Image to Harbor for Testing

1. **Log in to Your Harbor Registry**
   - Use Docker to log in to your Harbor registry:
     ```sh
     docker login harbor-test.com
     ```
   - Enter your Harbor username and password when prompted.

2. **Push a Test Image to Harbor**
   - Pull a sample image from Docker Hub:
     ```sh
     docker pull busybox
     ```
   - Tag the image to prepare it for pushing to your Harbor registry:
     ```sh
     docker tag busybox:latest harbor-test.com/private-repo/busybox:1.0.0
     ```
   - Push the tagged image to Harbor:
     ```sh
     docker push harbor-test.com/private-repo/busybox:1.0.0
     ```

### Pulling the Image Using `kubectl` Automation

1. **Encode the `ca.crt` File in Base64**
   - The `ca.crt` file must be encoded in Base64 to be used in Kubernetes configurations.
   - Run the `yaml-editor.sh` script to encode the certificate and update the `regain-access.yaml` file:
     ```sh
     ./certs-script/yaml-editor.sh
     ```

2. **Apply the Configuration to Kubernetes**
   - Deploy the updated Kubernetes configuration:
     ```sh
     cd kubernetes-configs
     kubectl apply -f regain-access.yaml
     ```

### Pulling the Image from Harbor Manually

#### a. Encode the `ca.crt` Certificate in Base64

1. **Open a Terminal Window**
   - Open a terminal window on each virtual machine (VM) where you need to pull the image.

2. **Encode the Certificate**
   - Use the `base64` tool to encode the `ca.crt` certificate file:
     ```sh
     cat /path/to/your/ca.crt | base64 > ca.crt.base64
     ```
   - Replace `/path/to/your/ca.crt` with the actual path to your certificate file.
   - This command generates a new file named `ca.crt.base64` containing the encoded certificate.

#### b. Deploy the `regain-access` DaemonSet

1. **Apply the DaemonSet Configuration**
   - Deploy the `regain-access-manual.yaml` DaemonSet to your Kubernetes cluster:
     ```sh
     kubectl apply -f regain-access-manual.yaml
     ```

2. **Add the Certificate to Each Pod**
   - List the pods to find the names of the pods created by the DaemonSet:
     ```sh
     kubectl get pods -o wide
     ```
   - Connect to each pod and add the encoded certificate:
     ```sh
     kubectl exec -it <pod_name> -- bash
     apiclient set pki.my-trusted-bundle.data="BASE64_CERT" \
     pki.my-trusted-bundle.trusted=true
     ```
   - Replace `<pod_name>` with the actual pod name and `BASE64_CERT` with the content of the `ca.crt.base64` file.





## Sources

- [Create the certificate](https://goharbor.io/docs/2.10.0/install-config/configure-https/)
- [Add the certificate to Bottlerocket](https://bottlerocket.dev/en/os/1.19.x/api/settings/pki/)
- [Add Docker username and password](https://bottlerocket.dev/en/os/1.19.x/api/settings/container-registry/)
- [Harbor releases page](https://github.com/goharbor/harbor/releases)

---

This guide provides detailed steps to install and configure Harbor, push and pull images, and manage certificates both automatically using Kubernetes and manually. Adjust the commands and paths as needed for your specific environment.