# TMNF-Docker
TMNF-Docker is a Linux-based Docker environment for running [TrackMania Nations Forever](https://www.trackmaniaforever.com/) with [TMLoader](https://tomashu.dev/software/tmloader/) 
using headless GPU rendering. The game runs inside the container through Wine with support for both Vulkan (via DXVK) and OpenGL-based rendering. A VNC server can be enabled to view
the graphical output of the container. In addition the container includes a default TrackMania profile, allowing the game to be used immediately out of the box without additional 
configuration.

This project was originally designed for AI training workflows, but it can also be used for regular gameplay, testing, or experimentation. Special thanks go to the creators of [egl-docker](https://github.com/jeasinema/egl-docker), 
which provided important foundations for the GPU handling used in this setup.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Build the Container](#build-the-container)
- [Running the Container](#running-the-container)
    - [VNC](#vnc)
    - [Rendering Options](#rendering-options)
        - [Vulkan (DXVK)](#vulkan-dxvk)
        - [VirtualGL](#virtualgl)

  ---
## Prerequisites
If you are on Linux, you should use Docker Engine instead of Docker Desktop, as Docker Desktop does not support GPU-related workloads on Linux. For more information, see this 
[forum thread](https://forums.docker.com/t/cant-start-containers-with-gpu-access-on-linux-mint/144606/3). Additionally, you may need to install the NVIDIA Container Toolkit 
if you have not done so already.

---

## Build the Container
Clone the repository and build the image by running:
```bash
git clone https://github.com/SgSiegens/TMNF-Docker 
cd TMNF-Docker
docker build -t <container_name> .
```

---

## Running the Container
To start the container, simply run:
```bash
docker run --gpus all -it <container_name>:latest /bin/bash
```
--- 
### VNC
If you also want to enable VNC access, you need to expose the VNC port:
```bash
docker run -p <port:port> --gpus all -it <container_name>:latest /bin/bash
```
By default, the container uses port **5900:5900** for VNC. After the container is running, start the VNC server by executing the `start-vnc.sh` script from outside the container:
```bash
docker exec -it <container_id> start-vnc.sh
```
You can find the `<container_id>` by running `docker ps`. Once the script starts, it will display the IP address where you can access the VNC session using your VNC viewer. 
After that, you will be prompted to enter the VNC password configured for the user. By default, the password is `mypasswd`.

--- 
### Rendering Options

#### Vulkan(DXVK)
The container uses DXVK by default, which translates DirectX calls to Vulkan. To verify that Vulkan rendering is working, run the following command inside the container:
```bash 
vkcube
```
You can view the output through a VNC session and confirm GPU activity on the host system (e.g. using the `nvidia-smi` command on NVIDIA hardware). To run the game, simply launch it through Wine as 
you normally would, no additional commands are required.

Vulkan works correctly for the game itself however the TMLoader GUI does not currently render properly when using Vulkan (see this [issue]()). The game can still be started through TMLoader via console.
If you prefer not to use Vulkan, you can switch to OpenGL by using VirtualGL instead.

#### VirtualGL
You can run the game using OpenGL through VirtualGL. First, check the detected EGL devices inside the container:
```bash
/opt/VirtualGL/bin/eglinfo -e
```
The output lists EGL devices and their associated `/dev/dri` card paths. Select the GPU you want to use and test hardware-accelerated OpenGL rendering with:
```bash
vglrun -d /dev/dri/card1 /opt/VirtualGL/bin/glxspheres64
```
or, if necessary:
```bash
vglrun -d egl1 /opt/VirtualGL/bin/glxspheres64
```
If the renderer shown in the output matches your GPU, then hardware acceleration is working correctly. You can also double-check this by opening a VNC session to view the desktop and confirming GPU usage, 
as described in the Vulkan section. Applications can be run with GPU-accelerated OpenGL by prefixing the command with `vglrun`, for example:
```bash
vglrun -d <eglx_or_dri_device_path> <your_command>
```
Because Wine uses DXVK by default, DXVK must be disabled to force OpenGL. Set the following environment variable:
```bash
export WINEDLLOVERRIDES="d3d9=b;d3d10=b;d3d10_1=b;d3d10core=b;d3d11=b;dxgi=b"
```
A few additional notes apply if you are using `vglrun` in a Python-based workflow, for example when training a TMNF agent using PyTorch. In such cases you may encounter errors such as:
```bash
Unable to load any of {libcudnn_graph.so.9.1.0, libcudnn_graph.so.9.1, libcudnn_graph.so.9, libcudnn_graph.so}
Invalid handle. Cannot load symbol cudnnCreate
```
The simplest workaround is not to run your entire Python script through `vglrun` and instead wrap only the game-launching command inside your script with `vglrun`. If that is not possible, you can dynamically 
load the required CUDA libraries by providing an additional `-ld` parameter to VirtualGL, as described [here](https://github.com/MorphoCloud/MorphoCloudWorkflow/issues/111#issuecomment-2864789501) and [here](https://github.com/VirtualGL/virtualgl/issues/227):

```bash
vglrun -d <eglx_or_dri_device_path> -ld <cuda_lib_path> <your_command>
```

For reference in a Conda environment we have found the required CUDA libraries under: 

```bash
/opt/conda/pkgs/pytorch-2.4.0-py3.11_cuda12.4_cudnn9.1.0_0/lib/python3.11/site-packages/torch/lib
```

If you are unsure where the CUDA libraries are located, you can search for them with:

```bash
find / -name "libcudnn_graph*.so*" 2>/dev/null
```

