FROM python:3.11-slim

WORKDIR /app

# 复制所有文件到工作目录
COPY . /app/

# 安装所有依赖
RUN pip install --no-cache-dir -r requirements.txt

# 环境变量设置 - 不再在Dockerfile中硬编码DATABASE_URL
ENV PORT=8000
ENV SECRET_KEY=aflepwqnasldn 

# 启动应用
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
