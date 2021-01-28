# Financial Platform
 FISCO-BCOS 区块链大项目 

iview admin为项目前端（使用iview admin模板），server为项目后端。

- [项目说明报告](https://shimo.im/docs/xhnamRJQnoANkMHa)
- [最终制品说明](https://shimo.im/docs/CvJMmcjsQ0kyjWBq)

### 说明
- sol文件位于文件夹下 /server/packages/cli/contracts/Financial Platform.sol

## 启动项目

### 启动链端

- 启动链端

### 启动后端

- 按照 官网教程安装nodejs sdk，对证书配置路径进行修改。

- 在server文件夹下执行：

  ```
  npm config set registry https://registry.npm.taobao.org	//替换为淘宝镜像，速度快
  
  //下载依赖
  npm install
  npm run repoclean
  npm run bootstrap
  ```

- 进入clis文件夹，运行指令

  ```
  node app.js
  ```


### 启动前端

- web-front文件夹运行指令

  ```
  npm install	
  npm run dev	
  ```


### 成功后会自动跳到浏览器
