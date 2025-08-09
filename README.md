# Módulo Terraform para Instalação do Karpenter na AWS

Este módulo do Terraform é projetado para automatizar a instalação e configuração do [Karpenter](https://karpenter.sh/) em um cluster Amazon EKS (Elastic Kubernetes Service). Ele provisiona todos os recursos necessários na AWS, incluindo a Role do IAM para o serviço do Karpenter, a Role para os Nós provisionados pelo Karpenter, a Fila SQS para eventos e o Instance Profile.

Além disso, o módulo realiza a instalação do Karpenter via Helm e configura os recursos essenciais no Kubernetes, como o `NodePool` e o `EC2NodeClass`, para que o Karpenter possa começar a gerenciar os nós do cluster de forma eficiente.

## Pré-requisitos

Antes de utilizar este módulo, você precisa ter:

1.  Um **Cluster EKS** já existente e em execução.
2.  O `kubectl` configurado para se comunicar com o seu cluster.
3.  O Terraform (versão 1.0+) instalado.
4.  As credenciais da AWS configuradas no ambiente onde o Terraform será executado.

---

## 💡 Dica: Obtendo Dados do Cluster EKS Dinamicamente

Para simplificar a integração e manter o código limpo, o módulo foi projetado para obter as informações do cluster EKS dinamicamente usando fontes de dados (`data`) do Terraform. Isso evita a necessidade de passar manualmente detalhes como o endpoint do cluster, o token de autenticação ou o certificado da autoridade de certificação (CA).

Basta garantir que o nome do cluster (`name`) nos blocos de dados corresponda ao seu cluster EKS existente.

```hcl
data "aws_eks_cluster" "main" {
  name = "nome-do-seu-cluster-eks"
}

data "aws_eks_cluster_auth" "main" {
  name = "nome-do-seu-cluster-eks"
}
```

Esses blocos de dados fornecerão automaticamente ao provedor do Kubernetes e do Helm as informações de autenticação necessárias para interagir com seu cluster.

---

## Exemplo de Uso

Abaixo está um exemplo completo de como utilizar este módulo. Certifique-se de que os `providers` (aws, kubernetes, helm) estejam configurados corretamente.

```hcl
# Configure os provedores necessários
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# Bloco de dados para buscar informações do cluster EKS
data "aws_eks_cluster" "main" {
  name = "meu-cluster-de-producao"
}

data "aws_eks_cluster_auth" "main" {
  name = "meu-cluster-de-producao"
}

# Instanciando o módulo Karpenter
module "karpenter" {
  source = "./terraform-aws-karpenter" # Caminho para o diretório do módulo

  # Variáveis essenciais
  region       = "us-east-1"
  project_name = "meu-projeto-incrivel"

  # Configurações do NodePool (Opcional)
  nodepool_instance_families = ["t3", "m5", "c5"]
  nodepool_instance_sizes    = ["medium", "large", "xlarge"]
  nodepool_capacity_types    = ["spot"]

  # Versão do Karpenter (Opcional)
  karpenter_version = "v1.6.0"
}
```

## Entradas (Inputs)

| Nome                           | Descrição                                                                                                                                                           | Tipo           | Padrão                               | Obrigatório |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------ | :---------: |
| `region`                       | Região onde os recursos serão construídos.                                                                                                                          | `string`       | -                                    |     Sim     |
| `project_name`                 | Nome do projeto, usado para nomear recursos e tags.                                                                                                                 | `string`       | -                                    |     Sim     |
| `solidstack_vpc_module`        | Se `true`, o módulo buscará recursos de VPC (subnets, etc.) criados por um módulo padrão, usando o SSM Parameter Store.                                               | `bool`         | `true`                               |     Não     |
| `pods_subnets`                 | Lista de IDs das subnets para os pods. Usado apenas se `solidstack_vpc_module` for `false`.                                                                           | `list(string)` | `[]`                                 |     Não     |
| `karpenter_version`            | A versão do chart Helm do Karpenter a ser instalada.                                                                                                                | `string`       | `"1.6.0"`                            |     Não     |
| `ami_family`                   | A família da AMI para os nós (ex: `Bottlerocket`, `AL2`).                                                                                                            | `string`       | `"Bottlerocket"`                     |     Não     |
| `ami_id`                       | O ID da AMI para os nós. Se especificado, sobrepõe a `ami_family`.                                                                                                    | `string`       | `""`                                 |     Não     |
| `nodepool_consolidate_after`   | A duração após a qual o Karpenter tentará consolidar os nós.                                                                                                        | `string`       | `"5m"`                               |     Não     |
| `nodepool_instance_families`   | Lista de famílias de instâncias permitidas para o NodePool.                                                                                                         | `list(string)` | `["m5", "c5", "c6a", "m6a", "c7a"]`   |     Não     |
| `nodepool_capacity_types`      | Tipos de capacidade permitidos para o NodePool (ex: `spot`, `on-demand`).                                                                                             | `list(string)` | `["spot", "on-demand"]`              |     Não     |
| `nodepool_instance_sizes`      | Lista de tamanhos de instância permitidos para o NodePool (ex: `large`, `xlarge`).                                                                                    | `list(string)` | `["large", "xlarge", "2xlarge"]`     |     Não     |

## Saídas (Outputs)

Este módulo não possui saídas (`outputs`) no momento.

## Provedores Terraform

| Nome         | Versão   |
| ------------ | -------- |
| **aws**      | `~> 5.0` |
| **kubernetes** | `~> 2.0` |
| **helm**     | `~> 2.0` |

## Recursos Criados

-   **AWS IAM Role**: Para o service account do Karpenter.
-   **AWS IAM Role**: Para os nós provisionados pelo Karpenter.
-   **AWS IAM Instance Profile**: Para associar a role aos nós.
-   **AWS SQS Queue**: Para o provisionamento baseado em eventos.
-   **Helm Release**: Para a instalação do Karpenter no cluster.
-   **Kubernetes Manifests**:
    -   `NodePool`: Define o comportamento padrão do provisionamento de nós.
    -   `EC2NodeClass`: Define a configuração específica da AWS para os nós.
-   **Kubernetes Auth**: Configura o `aws-auth` ConfigMap para permitir que os nós se juntem ao cluster.
