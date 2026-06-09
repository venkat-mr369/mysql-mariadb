GitHub Repository
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── network.tf
│   ├── firewall.tf
│   ├── compute.tf
│   ├── storage.tf
│   ├── loadbalancer.tf
│   └── terraform.tfvars
│
├── ansible/
│   ├── inventory
│   ├── playbook.yml
│   ├── roles/
│   │   ├── pxc/
│   │   └── proxysql/
│
├── scripts/
│   ├── bootstrap.sh
│   ├── mysql_secure.sh
│   └── healthcheck.sh
│
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
│
└── docs/
    ├── architecture.png
    └── deployment-guide.md
