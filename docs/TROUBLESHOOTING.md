# Troubleshooting Guide

## Common Issues and Solutions

### GPU Not Detected

**Symptoms**: ComfyUI runs but doesn't use GPU, slow generation

**Solutions**:

1. Verify Nvidia Container Toolkit is installed:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

2. If the above fails, reinstall:
```bash
# Ubuntu/Debian
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

3. Verify GPU is visible in container:
```bash
docker-compose exec comfyui nvidia-smi
```

---

### Out of Memory Errors

**Symptoms**: CUDA out of memory, generation fails

**Solutions**:

1. Edit `docker-compose.yml`, add under `environment:`:
```yaml
- PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

2. Restart:
```bash
docker-compose restart
```

3. Use lower resolution/batch size in workflows
4. Use GGUF or quantized models

---

### Custom Node Import Errors

**Symptoms**: Red nodes, missing dependencies

**Solutions**:

1. Check logs:
```bash
docker-compose logs | grep -i error
```

2. Most errors are warnings and don't affect functionality

3. To reinstall dependencies:
```bash
docker-compose exec comfyui bash
cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes/[node_name]
pip3 install -r requirements.txt
exit
docker-compose restart
```

---

### Port Already in Use

**Symptoms**: Cannot start, port 8188 in use

**Solution**: Edit `docker-compose.yml`:
```yaml
ports:
  - "8189:8188"  # Change 8189 to any free port
```

---

### Permission Denied Errors

**Symptoms**: Cannot write files, permission errors

**Solution**:
```bash
sudo chown -R $USER:$USER data/
docker-compose restart
```

---

### Container Won't Start

**Symptoms**: docker-compose up fails

**Steps**:

1. Check logs:
```bash
docker-compose logs
```

2. Verify Docker is running:
```bash
sudo systemctl status docker
```

3. Rebuild from scratch:
```bash
docker-compose down
docker system prune -a
docker-compose build --no-cache
docker-compose up -d
```

---

### Slow Performance

**Symptoms**: Generation takes too long

**Solutions**:

1. Verify GPU is being used:
```bash
watch -n 1 nvidia-smi
```

2. Use optimized models (GGUF, FP16)
3. Reduce resolution/batch size
4. Check CPU usage - if high, may indicate CPU bottleneck

---

### Models Not Loading

**Symptoms**: Models folder empty or not recognized

**Solutions**:

1. Verify volume mount in `docker-compose.yml`
2. Place models in correct directory:
```bash
data/ComfyUI-Easy-Install/ComfyUI/models/checkpoints/
```

3. Check external model paths:
```bash
cat config/extra_model_paths.yaml
```

4. Restart container:
```bash
docker-compose restart
```

---

### Update Script Fails

**Symptoms**: ./update.sh errors

**Solutions**:

1. Ensure container is running:
```bash
docker-compose ps
docker-compose up -d
```

2. Manual update:
```bash
docker-compose exec comfyui bash
cd /app/ComfyUI-Easy-Install/ComfyUI
git pull
cd custom_nodes/ComfyUI-Manager
git pull
exit
docker-compose restart
```

---

### Network Access Issues

**Symptoms**: Cannot access from other devices

**Solutions**:

1. Verify firewall:
```bash
sudo ufw allow 8188/tcp
```

2. Check container is listening on 0.0.0.0:
```bash
docker-compose exec comfyui netstat -tlnp | grep 8188
```

3. Access via: `http://SERVER_IP:8188`

---

### Build Takes Too Long

**Symptoms**: docker-compose build > 30 minutes

**Solutions**:

1. This is normal for first build (10-15 min typical)
2. Use build cache for subsequent builds
3. Check internet speed - downloads PyTorch and clones repos

---

### Workflows Not Saving

**Symptoms**: Workflows disappear after restart

**Solutions**:

1. Verify volume mount exists:
```bash
ls -la data/ComfyUI-Easy-Install/ComfyUI/user/default/workflows/
```

2. Check permissions:
```bash
sudo chown -R $USER:$USER data/
```

3. Save workflows via ComfyUI interface, not just in browser

---

## Getting Help

If none of these solutions work:

1. Check ComfyUI logs:
```bash
docker-compose logs -f comfyui
```

2. Check GitHub issues:
   - [This repo](https://github.com/tomorrowflow/ComfyUI-Easy-Install-docker/issues)
   - [ComfyUI](https://github.com/comfyanonymous/ComfyUI/issues)
   - [Easy Install](https://github.com/Tavris1/ComfyUI-Easy-Install/issues)

3. Provide these details when asking for help:
   - OS and version
   - GPU model and driver version
   - Docker and docker-compose version
   - Full error logs
   - Steps to reproduce