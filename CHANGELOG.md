# Changelog

## 1.0.0 (2026-10-20)


### ✨ Features

* **bootstrap:** add remote state, GitHub OIDC roles and budget alert ([19de25f](https://github.com/LucasCA-Git/tf-painel/commit/19de25f59c4a189fc4aed8e816504780d69750f4))
* **compute:** add SSM-managed EC2 module with optional ALB ([2430936](https://github.com/LucasCA-Git/tf-painel/commit/2430936b2d0d3116a4c1fa164da10c544851069b))
* **envs:** add dev and prod environments ([0be5277](https://github.com/LucasCA-Git/tf-painel/commit/0be5277a895776b3cde767202e57609a167207ad))
* **network:** add multi-AZ VPC module with optional NAT and flow logs ([87f5a51](https://github.com/LucasCA-Git/tf-painel/commit/87f5a51cc617a8c35f5471f83c812c4344904c8e))


### 🎛️ CI/CD

* add control panel workflow with run toggles ([005875d](https://github.com/LucasCA-Git/tf-painel/commit/005875dad6399f1f316d2e3710c3291a8b772a0e))
* add deploy pipeline with prod approval gate ([a4250aa](https://github.com/LucasCA-Git/tf-painel/commit/a4250aa62f27cdcadc16837428a5cbedb6a91250))
* add drift detection and nightly destroy of dev ([b99e512](https://github.com/LucasCA-Git/tf-painel/commit/b99e512bddfb040055eb8c2d68d06b227086cdde))
* add pull request pipeline with plan comment and infracost ([c5b94b0](https://github.com/LucasCA-Git/tf-painel/commit/c5b94b0c681e110a3d82e5eda01c3f4647d09faa))
* add reusable quality and terraform workflows ([c38395e](https://github.com/LucasCA-Git/tf-painel/commit/c38395e3b38ea98bf4431e02c1631e9554661ef4))
* **release:** add release-please with semantic changelog ([e9c2a5f](https://github.com/LucasCA-Git/tf-painel/commit/e9c2a5fcc14e463c2b7d59fc653cdc71a629bb0b))


### 📚 Documentation

* add bilingual README with panel guide ([8edfa96](https://github.com/LucasCA-Git/tf-painel/commit/8edfa96c91bedd29769ffb98a2e28c2e9bd79142))
* **adr:** record architecture decisions 0001 to 0005 ([edee8ee](https://github.com/LucasCA-Git/tf-painel/commit/edee8ee0a7afbe8e5c22e246c2530245d2b266ef))
* **bmad:** add architecture and epics with stories ([19e9f42](https://github.com/LucasCA-Git/tf-painel/commit/19e9f42dd4f5470745915b9c16d988eaa49309fd))
* **bmad:** add product brief for tf-painel ([d16d891](https://github.com/LucasCA-Git/tf-painel/commit/d16d8912277d855fc7c4b614e6854d9d20add974))


### 🧪 Tests

* **compute:** cover placement, hardening and ALB toggle ([888d4fd](https://github.com/LucasCA-Git/tf-painel/commit/888d4fd62ec79f6878e1dc550035b9c1acb4d528))
* **network:** cover subnet math and toggles with a mocked provider ([60629d3](https://github.com/LucasCA-Git/tf-painel/commit/60629d36063d231a960e224ac8d8f8605100b474))
