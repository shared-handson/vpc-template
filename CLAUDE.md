# CLAUDE.md - VPC-TEMPLATE Project

## Project Overview

VPC-TEMPLATE プロジェクトは、AWS における VPC 構築のテンプレートプロジェクトです。
このプロジェクトを基盤として、様々な VPC 環境を構築することができます。

## Project Purpose

- AWS VPC 構築のベースラインテンプレートとして機能
- NAT Bastion を使用したコスト効率の良い NAT 構成
- セキュアなネットワーク構成のベストプラクティスを実装
- 再利用可能なモジュール構成で、他のプロジェクトへの展開を容易に

## Architecture Components

### Module Structure

プロジェクトは単一の統合モジュールで構成されています:

**network モジュール**: VPC、サブネット、ルートテーブル、VPC エンドポイント、Route53 プライベートホストゾーン、キーペア、セキュリティグループ、IAM ロール/インスタンスプロフィール、NAT Bastion インスタンスを一元管理

モジュール内部は以下のファイルで機能別に整理されています:

- **vpc.tf**: VPC、サブネット、ルートテーブル、VPC エンドポイント、Route53 プライベートホストゾーンを管理
- **security.tf**: キーペア、セキュリティグループ、IAM ロール/インスタンスプロフィールを管理
- **natbastion.tf**: NAT 機能を持つ Bastion インスタンス、EIP、ルート設定、DNS レコードを管理

### Key Features

- Multi-AZ 対応の VPC 構成
- Public/Private サブネットの自動セグメンテーション
- EC2 ベースの NAT Bastion(NAT Gateway の代替としてコスト削減)
- S3/DynamoDB への VPC エンドポイント(Gateway タイプ)
- SSM 経由でのインスタンス管理サポート
- ED25519 アルゴリズムを使用した秘密鍵自動生成
- プライベートホストゾーンでの DNS 名前解決

## Network Design

### CIDR 構成

デフォルトの VPC CIDR: 10.0.0.0/16

- Public Subnet: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24 (各 AZ)
- Private Subnet: 10.0.129.0/24, 10.0.130.0/24, 10.0.131.0/24 (各 AZ)

CIDR 計算ロジック:

- Public: cidrsubnet(vpc_cidr, 8, 0 + 1 + i)
- Private: cidrsubnet(vpc_cidr, 8, 128 + 1 + i)

### Routing Strategy

- Public Subnet: Internet Gateway 経由でインターネットへルーティング
- Private Subnet: NAT Bastion 経由でインターネットへルーティング(各 AZ 個別のルートテーブル)

## Security Considerations

### Bastion Instance

- SSH 接続はインターネットから許可(0.0.0.0/0)されているため、適切なアクセス制御が必要
- fail2ban によるブルートフォース攻撃対策を実装
- ポートフォワーディングのみ許可する SSH 設定
- VPC 内からの全トラフィックを許可

### Key Management

- 秘密鍵は Terraform 実行時に自動生成
- iscreate_key_bastion フラグが true の場合、natbastion.pem としてローカルファイルに保存
- iscreate_key_workload フラグが true の場合、workload.pem としてローカルファイルに保存
- デフォルトでは両フラグとも false のため、ファイルは生成されない

## AMI Management

### Supported AMIs

- Amazon Linux 2023 (AMD64/ARM64)
- Ubuntu 24.04 LTS (AMD64/ARM64)

### AMI Selection Strategy

- デフォルト: AWS SSM Parameter Store から最新 AMI を自動取得
- Static AMI 指定: terraform.tfvars で static\_\*変数を設定することで固定 AMI 使用可能

## Resource Naming Convention

全てのリソースは以下の命名規則に従います:

```
{resource-type-prefix}-{resource-name}-{project_name}
```

例:

- VPC: vpc-{project_name}
- Subnet: sb-pub1a-{project_name}, sb-pri1a-{project_name}
- Security Group: sg-natbastion-{project_name}
- EC2 Instance: ec2-natbastion-{project_name}
- Key Pair: kp-natbastion-{project_name}, kp-workload-{project_name}

## Default Tags

全リソースに自動的に以下のタグが付与されます:

- Owner: var.owner_name
- Project: var.project_name
- ManagedBy: terraform

## Required Variables

必ず設定が必要な変数:

- owner_name: オーナー名
- project_name: プロジェクト名

## Optional Variables

デフォルト値が設定されているため、オプション:

- aws_region: デフォルト ap-northeast-1
- az_count: デフォルト 3
- vpc_cidr: デフォルト 10.0.0.0/16
- domain_name: デフォルト internal
- natbastion_instance: NAT Bastion インスタンスの詳細設定(instance_type, architecture, az_2word, root_volume_size)
- static\_\*: 静的 AMI ID 指定(static_al2023_amd64, static_al2023_arm64, static_ubuntu_amd64, static_ubuntu_arm64)
- iscreate_key_bastion: Bastion 秘密鍵の pem ファイル書き出しフラグ(デフォルト false)
- iscreate_key_workload: Workload 秘密鍵の pem ファイル書き出しフラグ(デフォルト false)

## Bastion Instance Configuration

Bastion インスタンスは以下の機能を持ちます:

### NAT 機能

- iptables による NAT 設定(MASQUERADE)
- IP Forwarding の有効化
- source_dest_check を無効化してルーティング機能を実現

### セキュリティ機能

- fail2ban: SSH 接続の試行回数制限
- ポートフォワーディング専用 SSH 設定: TTY 無効化、コマンド実行不可

### 管理機能

- SSM 経由でのアクセスをサポート(AmazonSSMManagedInstanceCore)
- Route53 プライベートゾーンに自動 DNS 登録: bastion.{domain_name}

## Outputs

### connect_from_inet

インターネットからの接続情報:

- natbastion: NAT Bastion EIP の CIDR 形式(/32)

## Extension Points

このテンプレートを拡張する際の推奨ポイント:

1. 新しい workload モジュールの追加
2. Application Load Balancer や NLB の追加
3. RDS、ElastiCache 等のマネージドサービス追加
4. VPC エンドポイント(Interface 型)の追加
5. VPC Peering や Transit Gateway の設定

## File Structure

```
terraform/
├── provider.tf                # プロバイダー設定、データソース定義
├── network-main.tf            # メインコンフィグ、ローカル変数、モジュール呼び出し、秘密鍵ファイル出力
├── network-variables.tf       # 変数定義
├── network-outputs.tf         # 出力定義
├── terraform.tfvars.example   # 設定例
└── modules/
    └── network/               # 統合ネットワークモジュール
        ├── vpc.tf             # VPC、サブネット、ルートテーブル、VPCエンドポイント
        ├── security.tf        # キーペア、セキュリティグループ、IAMロール
        ├── natbastion.tf      # NAT Bastionインスタンス、EIP、ルート、DNSレコード
        ├── variables.tf       # モジュール変数定義
        ├── outputs.tf         # モジュール出力定義
        └── userdata/
            └── natbastion.sh  # Bastion初期化スクリプト
```

## Terraform Version Requirements

- Terraform: >= 1.12
- AWS Provider: ~> 6.15
- Random Provider: ~> 3.7
- TLS Provider: ~> 4.1
- Local Provider: ~> 2.5

## Notes

- terraform.tfvars ファイルは.gitignore に含めること(機密情報を含む可能性があるため)
- 生成された秘密鍵ファイル(\*.pem)は.gitignore に含めること
- Bastion インスタンスは単一 AZ 配置のため、AZ 障害時には Private サブネットからのインターネット接続が不可
- コスト最適化のため、NAT Gateway の代わりに EC2 ベースの NAT を使用
