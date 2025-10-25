# 🌙 Sun DevOps Beginner

Dự án học DevOps cơ bản: triển khai hạ tầng AWS (S3 + Lambda + DynamoDB) bằng **Terraform**, hỗ trợ nhiều môi trường (`dev`, `staging`) với **backend S3**.

---

## 🎯 Mục tiêu
- Tạo **S3 bucket** để upload ảnh.
- Tạo **DynamoDB table** để lưu metadata ảnh.
- Tạo **AWS Lambda function** để resize ảnh khi có upload mới.
- Quản lý toàn bộ hạ tầng bằng **Terraform**.
- Hỗ trợ **nhiều môi trường** (dev, staging) với state riêng biệt.
- Thực hành quản lý **Terraform state, backend, lockfile**.

---

## 📂 Cấu trúc thư mục

```bash
sun-dev-ops-beginner/
├── main.tf
├── variables.tf
├── provider.tf
├── README.md
├── envs/
│   ├── dev/
│   │   ├── dev.tfvars
│   │   ├── backend.config
│   ├── staging/
│   │   ├── staging.tfvars
│   │   ├── backend.config
├── lambda/
│   └── lambda.zip
└── .gitignore
```

# ⚙️ Hướng dẫn setup & chạy
## 1️⃣ Clone repo
```
git clone https://github.com/phucnt-2896/sun-dev-ops-beginner.git
cd sun-dev-ops-beginner
```

## 2️⃣ Khởi tạo Terraform cho môi trường dev
 ```
terraform init -backend-config="./envs/dev/backend.config"
```

## 3️⃣ Apply infrastructure dev
```
terraform apply -var-file="./envs/dev/dev.tfvars"
```

## 4️⃣ Chạy cho môi trường staging
```
terraform init -reconfigure -backend-config="./envs/staging/backend.config"
terraform apply -var-file="./envs/staging/staging.tfvars"
```

## 5️⃣ Xóa các service
```
terraform init -backend-config="./envs/dev/backend.config"
terraform destroy -auto-approve -var-file="./envs/dev/dev.tfvars"
```