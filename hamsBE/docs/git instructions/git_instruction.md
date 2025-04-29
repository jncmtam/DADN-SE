# Hướng dẫn Git từ cơ bản đến nâng cao

## 1. Thiết lập ban đầu
```sh
git config --global user.name "Tên của bạn"
git config --global user.email "email@example.com"
git init  # Khởi tạo repository mới
```

## 2. Quản lý repository
```sh
git clone <URL>  # Sao chép repo từ GitHub
git remote add origin <URL>  # Thêm remote
git remote -v  # Xem danh sách remote
```

## 3. Làm việc với thay đổi cục bộ
```sh
git status  # Kiểm tra trạng thái
git add <file>  # Thêm file vào staging
git add .  # Thêm tất cả file
git commit -m "Thông điệp commit"
git commit --amend  # Sửa commit cuối
```

## 4. Làm việc với branch
```sh
git branch  # Liệt kê branch
git branch <tên_branch>  # Tạo branch mới
git checkout <tên_branch>  # Chuyển branch
git checkout -b <tên_branch>  # Tạo và chuyển branch mới
git branch -d <tên_branch>  # Xóa branch
git merge <tên_branch>  # Gộp branch
```

## 5. Đồng bộ với GitHub
```sh
git push origin <tên_branch>  # Đẩy lên GitHub
git push -u origin <tên_branch>  # Đẩy và theo dõi branch
git pull origin <tên_branch>  # Lấy và gộp thay đổi
git fetch origin  # Lấy dữ liệu nhưng không merge
```

## 6. Xem lịch sử và so sánh
```sh
git log  # Xem lịch sử commit
git log --oneline  # Xem lịch sử ngắn
git diff  # So sánh thay đổi
git diff --staged  # So sánh với commit cuối
```

## 7. Hoàn tác thay đổi
```sh
git checkout -- <file>  # Hủy thay đổi chưa staged
git reset <file>  # Gỡ file khỏi staged
git reset --hard  # Hủy toàn bộ thay đổi
git revert <commit_hash>  # Tạo commit hoàn tác
```

## 8. Làm việc với stash
```sh
git stash  # Lưu thay đổi tạm thời
git stash list  # Xem stash
git stash apply  # Áp dụng stash
git stash drop  # Xóa stash
```

## 9. Xử lý xung đột & nâng cao
```sh
git rebase <branch>  # Chuyển commit lên trên branch khác
git cherry-pick <commit_hash>  # Lấy một commit cụ thể
git clean -f  # Xóa file untracked
git mergetool  # Dùng công cụ giải quyết conflict
```

## 10. Xử lý lỗi nhanh
### 10.1 Lỡ commit sai branch
```sh
git checkout đúng-branch
git cherry-pick <commit_hash>
```
### 10.2 Lỡ push secret
```sh
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch secret.txt' --prune-empty --tag-name-filter cat -- --all
```
### 10.3 Lỡ merge nhầm
```sh
git reset --hard <commit_trước_merge>
```
### 10.4 Lỡ push sai
```sh
git push origin +<branch>  # Force push
```

## 11. Cách hoàn tác merge trong Git
### 11.1 Nếu chưa commit merge
```sh
git reset --hard HEAD  # Hủy merge
```
Hoặc:
```sh
git merge --abort  # Hủy merge đang diễn ra
```

### 11.2 Nếu đã commit merge nhưng chưa push
```sh
git reset --hard ORIG_HEAD  # Hoàn tác merge về commit trước đó
```
Hoặc:
```sh
git reset --hard <commit_truoc_merge>  # Reset về commit trước merge
```

### 11.3 Nếu đã push merge lên GitHub
#### Cách 1: Dùng force push (⚠️ Cẩn thận khi dùng)
```sh
git reset --hard ORIG_HEAD  # Reset về commit trước merge
git push --force origin main  # Cập nhật remote
```
⚠️ **Chỉ dùng nếu chắc chắn không có ai làm việc trên `main` sau merge.**

#### Cách 2: Dùng revert (an toàn hơn)
```sh
git revert -m 1 <commit_merge>  # Tạo commit hoàn tác merge
git push origin main
```

## 12. Merge file từ branch này sang branch khác
```sh
git checkout main
git checkout be/mqtt -- internal/mqtt/note.md
git status
git add internal/mqtt/note.md
git commit -m "Merge mqtt/note.md từ be/mqtt vào main"
git push origin main
```

## 13. Quy trình làm việc nhóm
```sh
git clone <URL>
git checkout -b feature/ten-tinh-nang
git add .
git commit -m "Mô tả thay đổi"
git push origin feature/ten-tinh-nang
gh pr create  # Tạo pull request
git pull origin main  # Cập nhật từ remote
```

## 14. Làm việc với nhiều remote
```sh
git remote add upstream https://github.com/company/repo.git
git fetch upstream  # Lấy thay đổi
git merge upstream/main  # Hợp nhất code mới
```

## 15. Quy trình làm việc trong công ty
### 15.1 Gitflow
- `main`: Chỉ chứa code production
- `develop`: Nhánh chính cho phát triển
- `feature/*`: Nhánh tính năng
- `release/*`: Chuẩn bị phát hành
- `hotfix/*`: Sửa lỗi khẩn cấp

### 15.2 Trunk-based development
- `main`: Code chính, luôn deploy được
- Pull request chỉ kéo dài tối đa 1-2 ngày
- Dùng feature toggle thay vì branch dài hạn

