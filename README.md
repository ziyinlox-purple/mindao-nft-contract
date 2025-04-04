# MinDAO NFT Contract

MinDAO 是一个基于 Aptos 区块链的 NFT 合约项目，使用 Move 语言开发。该项目提供了一个完整的 NFT 合约实现，支持 NFT 的创建、转移和管理等功能。

## 项目结构

```
mindao-nft-contract/
├── sources/           # Move 源代码目录
│   └── MinDao.move    # 主合约文件
├── build/             # 构建输出目录
├── Move.toml          # 项目配置文件
└── .env              # 环境配置文件
```

## 技术栈

- Move 语言
- Aptos 区块链
- AptosFramework
- AptosTokenObjects

## 安装要求

- Move CLI
- Aptos CLI
- Rust 工具链

## 安装步骤

1. 克隆项目仓库：
```bash
git clone https://github.com/ziyinlox-purple/mindao-nft-contract.git
cd mindao-nft-contract
```

2. 安装依赖：
```bash
aptos move compile
```

## 使用方法

1. 编译合约：
```bash
aptos move compile
```

2. 部署合约：
```bash
aptos move deploy-object --account-address <your-account-address>
```

## 合约功能

- NFT 创建
- NFT 转移
- NFT 所有权管理
- 元数据管理

## 开发指南

1. 确保已安装所有必要的开发工具
2. 在 `sources` 目录下进行合约开发
3. 使用 `aptos move test` 运行测试
4. 使用 `aptos move deploy-object` 部署合约

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

MIT License
