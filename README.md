# Nginx Reverse Proxy & Load Balancer Configuration

## 📋 Sơ đồ kiến trúc hệ thống

```
┌─────────────┐
│   Clients   │
└──────┬──────┘
       │ HTTPS:443
       ▼
┌──────────────────────┐
│   Nginx Proxy        │
│ (100.100.100.129)    │
│  HTTP→HTTPS redirect │
└──────┬──────────────┬────────┘
       │              │
   HTTP/WS        /api/
       │              │
       ▼              ▼ Load Balanced
┌────────────────┐  ┌──────────────────┐
│ React Frontend │  │ API Backend 1    │
│   :8080        │  │ 100.100.100.130  │
└────────────────┘  │    :9000         │
                    │                  │
                    │ API Backend 2    │
                    │ 100.100.100.131  │
                    │    :9000         │
                    └──────────────────┘
```

## 🎯 Tính năng chính

### 1. **Load Balancing - Cân bằng tải API Backend**
- **Thuật toán**: Round Robin (Mặc định)
- **Máy chủ Backend**:
  - `100.100.100.130:9000` (Node.js 1)
  - `100.100.100.131:9000` (Node.js 2)
- **Health Check**: 
  - `max_fails=3`: Tối đa 3 lần thất bại
  - `fail_timeout=30s`: Thời gian phục hồi 30 giây

### 2. **Bảo mật (Security)**

| Tính năng | Giải thích |
|-----------|-----------|
| **HTTP→HTTPS Redirect** | Tất cả request HTTP tự động chuyển hướng sang HTTPS |
| **SSL/TLS v1.2+** | Hỗ trợ TLS 1.2 và TLS 1.3 |
| **Security Headers** | X-Frame-Options, X-XSS-Protection, X-Content-Type-Options |
| **Hide Server Info** | Ẩn phiên bản Nginx (`server_tokens off`) |
| **Gzip Compression** | Nén dữ liệu (js, css, json, xml, svg) |

### 3. **Caching Strategy**

#### 📁 Static Files Caching
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$
- Thời gian lưu: 1 ngày (1d)
- Cache-Control: public, no-transform
- Không ghi log truy cập (access_log off)
```

#### 📄 Index.html Special Handling
```nginx
location = /index.html
- Thời gian lưu: 1 phút (1m)
- Cache-Control: no-store, no-cache, must-revalidate
- Đảm bảo lúc nào cũng fetch bản mới nhất
```

#### 🔌 API Response Caching
```nginx
location /api/
- Cache Zone: MY_API_CACHE (10MB, max 1GB, inactive 60m)
- Methods: GET requests only
- Valid duration:
  * 200/302 responses: 10 phút
  * 404 errors: 1 phút
- Bypass cache: Nếu có Authorization header hoặc cookie nocache
```

### 4. **WebSocket Support**
```nginx
- HTTP/1.1 upgrade
- Hỗ trợ real-time connections cho React frontend
```

### 5. **Nginx Core Optimization**

| Cấu hình | Giá trị | Lợi ích |
|----------|--------|---------|
| **worker_processes** | auto | Tự động dùng số lõi CPU |
| **worker_connections** | 1024 | Số kết nối tối đa per worker |
| **multi_accept** | on | Chấp nhận nhiều kết nối cùng lúc |
| **sendfile** | on | Zero-copy file transfer |
| **tcp_nopush** | on | Tối ưu network packets |
| **gzip_comp_level** | 5 | Cân bằng CPU vs compression |

---

## 🚀 Hướng dẫn cấu hình

### Bước 1: Tạo SSL Certificate

```bash
# Tạo thư mục SSL
mkdir -p /etc/nginx/ssl

# Tạo self-signed certificate (365 ngày)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/nginx/ssl/nginx-selfsigned.key \
-out /etc/nginx/ssl/nginx-selfsigned.crt

# Nhập thông tin:
# Country Name (2 letter code) [AU]: VN
# State or Province Name [Some-State]: Ho Chi Minh
# Locality Name (eg, city) []: Ho Chi Minh City
# Organization Name (eg, company) [Internet Widgits Pty Ltd]: Your Company
# Organizational Unit Name (eg, section) []: IT
# Common Name (eg, your server FQDN) []: 100.100.100.129
# Email Address []: admin@example.com
```

### Bước 2: Sao chép cấu hình

```bash
# Copy main nginx.conf
sudo cp nginx.conf /etc/nginx/

# Copy conf.d configuration
sudo cp conf.d/nginx.conf /etc/nginx/conf.d/

# Kiểm tra cú pháp
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Hoặc restart
sudo systemctl restart nginx
```

### Bước 3: Kiểm tra trạng thái

```bash
# Xem trạng thái Nginx
sudo systemctl status nginx

# Xem log lỗi
sudo tail -f /var/log/nginx/error.log

# Xem log truy cập
sudo tail -f /var/log/nginx/access.log

# Xem cache status
curl -i https://100.100.100.129/api/your-endpoint
# Kiếm header: X-Proxy-Cache (HIT/MISS/BYPASS)
```

---

## 📊 Thuật toán của Nginx

### **Event-Driven & Asynchronous**
- **Mô hình Event Loop**: Nginx sử dụng vài Worker Processes, mỗi process xử lý hàng ngàn kết nối đồng thời
- **Cơ chế Epoll (Linux) / Kqueue (BSD)**: Chỉ tập trung vào kết nối có dữ liệu, không polling từng cái
- **Non-blocking I/O**: Gửi request, không đợi, xử lý việc khác, quay lại khi có event

### **Load Balancing Algorithms**

| Thuật toán | Cách thức | Khi nào dùng |
|-----------|----------|-------------|
| **Round Robin** | Lần lượt a→b→c | Công bằng cho servers cơ bản |
| **Least Connections** | Server có kết nối ít nhất | Tránh quá tải server |
| **IP Hash** | Hash IP → cố định 1 server | Session persistence |
| **Generic Hash** | Hash theo URL/ID custom | Cache hoặc xử lý theo vùng |
| **Random** | Chọn ngẫu nhiên | Cluster rất lớn, giảm tính toán |

---

## 🔧 Điều chỉnh theo nhu cầu

### Nếu muốn đổi thuật toán Load Balancing:
```nginx
upstream api_backend {
    # least_conn;      # Ít kết nối nhất
    # ip_hash;         # Cố định IP
    # random;          # Ngẫu nhiên
    
    server 100.100.100.130:9000;
    server 100.100.100.131:9000;
}
```

### Nếu muốn thay đổi thời gian cache API:
```nginx
proxy_cache_valid 200 302 10m;  # Đổi từ 10m thành 5m, 30m, 1h, ...
```

### Nếu muốn tăng upload limit:
```nginx
client_max_body_size 50M;  # Thay đổi từ 10M sang 50M
```

### Nếu muốn thêm rate limiting:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

location /api/ {
    limit_req zone=api_limit burst=20;
    # ...
}
```

---

## 📝 Lưu ý

- Luôn test cấu hình với `nginx -t` trước khi apply
- Backup cấu hình cũ trước khi thay đổi
- Kiểm tra logs khi có lỗi
- Sử dụng reload thay vì restart để tránh downtime
- Cấu hình này dùng self-signed cert; dùng cert thực cho production

---

## 🆘 Troubleshooting

| Vấn đề | Giải pháp |
|--------|----------|
| **502 Bad Gateway** | Kiểm tra backend servers có chạy không |
| **SSL Certificate Error** | Regenerate certificate hoặc dùng cert hợp lệ |
| **Slow response** | Kiểm tra cache (X-Proxy-Cache header), tăng timeouts |
| **Too many redirects** | Kiểm tra HTTP→HTTPS redirect logic |
| **WebSocket error** | Đảm bảo Upgrade headers được set đúng |
