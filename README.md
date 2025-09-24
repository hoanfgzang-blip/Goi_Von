# Goi_Von
tải https://git-scm.com/downloads/win
Cài thì cứ spam next là được, để ý sẽ có phần Browse để lưu lại ở phân vùng khác
Muốn tải file về thì phải clone file về (nhớ backup để khi up lên mà có vấn đề thì còn sửa lại được)
Clone file: (mở bash của git)
cd [nơi lưu trữ]
git clone https://github.com/hoanfgzang-blip/Goi_Von.git 
Up file lên git
-Chọn file muốn up
git add [tên file]
hoặc 
git add . 
để chọn hết file để up
-Commit để lưu lại file vào lịch sử của git
git commit -m [mô tả thay đổi]
*yêu cầu khi commit phải ghi rõ tên, mục tiêu thay đổi để sau chỉnh sửa
-Up lên github nhóm
git push origin main
khi thao tác với folder git phải mở bash ở ngay nơi lưu trữ bằng lệnh cd hoặc là Shift + chuột phải rồi chọn bash ở vị trí lưu trữ

UP CHAY
Cũng được nhưng xong bị gặp vấn đề về phân bố file ban đầu hay như nào thì phải tự sửa


LƯU Ý
trước khi sửa file phải dùng lệnh git pull origin main 
nó sẽ là bước để lưu về máy (pull là lưu về push là tải lên) 

Đăng nhập github lên mt
tải cái này về: https://cli.github.com/
sau đó mở bash của git lên rồi gõ lệnh gh auth login
Enter 2 3 phát rồi đăng nhập trên web rồi chạy lại lệnh push là được
Đây là bước để bảo mật cái repo của ae nên phải làm cẩn thận, nếu tài khoản ae chưa được duyệt truy cập vào repo thì qua chat chung gọi 


Đây là cách sửa lỗi này khi chạy lệnh push
gõ 2 lệnh sau
git config user.name "username"
git config user.email "youremail@example.com"
là được 
