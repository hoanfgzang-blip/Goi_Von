CREATE DATABASE GoiVon;
GO

USE GoiVon;
GO


-- ========== BẢNG NỀN TẢNG (Không phụ thuộc) ==========

CREATE TABLE NHACC(
    ID_NHACC NVARCHAR(10) PRIMARY KEY NOT NULL,
    TEN_NHACC NVARCHAR(100) NOT NULL,
    DIA_CHI NVARCHAR(250),
    SO_DTH VARCHAR(20)
);
GO

CREATE TABLE KHACHHANG (
    ID_KH NVARCHAR(10) PRIMARY KEY NOT NULL,
    TEN_KH NVARCHAR(100) NOT NULL, 
    SO_DTH VARCHAR(20),
    DIA_CHI NVARCHAR(250),
    THANH_PHO NVARCHAR(50),
    QUOC_GIA NVARCHAR(50),
    DIEM_TICH_LUY INT DEFAULT 0
);
GO

CREATE TABLE SHIPPER(
    ID_SHIPPER NVARCHAR(10) PRIMARY KEY NOT NULL,
    TEN_SHIPPER NVARCHAR(100) NOT NULL,
    SO_DTH VARCHAR(20)
);
GO

-- ========== BẢNG SẢN PHẨM & KHO (Phụ thuộc) ==========

CREATE TABLE SAN_PHAM (
    ID_SANPHAM NVARCHAR(10) PRIMARY KEY NOT NULL,
    TEN_SANPHAM NVARCHAR(100) NOT NULL,
    ID_NHACC NVARCHAR(10) NOT NULL, --TRUY XUẤT NHÀ CUNG CẤP TỪ KHO HÀNG QUA BẢNG NAY BẰNG ID_SANPHAM
    DON_VI NVARCHAR(50),
    GIA_BAN MONEY NOT NULL,
    NGAY_SX DATE,
    LOAI_HANG NVARCHAR(50), -- Xác định loại hàng bằng cách đánh giấu loại hàng VD L'TRANGTRI' , L'DIENTU'
    NOI_SX NVARCHAR(100),

    CONSTRAINT FK_SANPHAM_NHACC FOREIGN KEY (ID_NHACC) REFERENCES NHACC(ID_NHACC)
);
GO

CREATE TABLE KHO_HANG(
    ID_SANPHAM NVARCHAR(10) PRIMARY KEY NOT NULL,
    SO_LUONG INT NOT NULL DEFAULT 0,
    
    CONSTRAINT FK_KHO_SANPHAM FOREIGN KEY (ID_SANPHAM) REFERENCES SAN_PHAM(ID_SANPHAM)
);
GO

CREATE TABLE NHAP_HANG(
    ID_PHIEUNHAP NVARCHAR(10) PRIMARY KEY NOT NULL,
    ID_NHACC NVARCHAR(10) NOT NULL,
    ID_SANPHAM NVARCHAR(10),
    SO_LUONGNHAP INT NOT NULL,
    GIA_NHAP MONEY NOT NULL,
    NGAY_NHAP DATE DEFAULT GETDATE(),

    CONSTRAINT FK_NHAPHANG_NHACC FOREIGN KEY (ID_NHACC) REFERENCES NHACC(ID_NHACC),
    CONSTRAINT FK_NHAPHANG_SANPHAM FOREIGN KEY (ID_SANPHAM) REFERENCES SAN_PHAM(ID_SANPHAM)
);
GO

-- ========== BẢNG GIAO DỊCH (Hóa đơn & Lịch sử) ==========

CREATE TABLE HOADON(
    ID_HOADON NVARCHAR(10) PRIMARY KEY NOT NULL,
    ID_KH NVARCHAR(10) NOT NULL,
    NGAY_TAO DATE DEFAULT GETDATE(),
    CHIETKHAU MONEY DEFAULT 0, -- VOUCHER + DISCOUNT
    TONG_TIEN_SP MONEY DEFAULT 0, -- TỔNG TIỀN CỦA SẢN PHẨM
    TONG_THANH_TOAN MONEY DEFAULT 0, -- TỔNG TIỀN PHẢI THANH TOÁN SAU KHI TRỪ ĐI CHIẾT KHẤU
    HINH_THUC INT NOT NULL DEFAULT 1, -- 1: Tại quầy, 2: Online
    TRANG_THAI INT NOT NULL DEFAULT 1, -- 1:Xác nhận, 2:Đang giao, 3:Hoàn thành, 4:Đã hủy
    
    ID_SHIPPER NVARCHAR(10) NULL, -- Có thể NULL nếu mua tại quầy
    NGAY_GIAO DATE NULL,

    CONSTRAINT FK_HOADON_KHACHHANG FOREIGN KEY (ID_KH) REFERENCES KHACHHANG(ID_KH),
    CONSTRAINT FK_HOADON_SHIPPER FOREIGN KEY (ID_SHIPPER) REFERENCES SHIPPER(ID_SHIPPER)
);
GO


CREATE TABLE DON_HANG (
    ID_HOADON NVARCHAR(10) NOT NULL,
    ID_SANPHAM NVARCHAR(10) NOT NULL,
    SO_LUONGBAN INT NOT NULL DEFAULT 1,
    DON_GIA MONEY NOT NULL, -- Giá bán thực tế tại thời điểm mua
    
    -- Khóa gộp
    PRIMARY KEY (ID_HOADON, ID_SANPHAM),

    CONSTRAINT FK_CHITIET_HOADON FOREIGN KEY (ID_HOADON) REFERENCES HOADON(ID_HOADON),
    CONSTRAINT FK_CHITIET_SANPHAM FOREIGN KEY (ID_SANPHAM) REFERENCES SAN_PHAM(ID_SANPHAM)
);
GO

CREATE TABLE LICH_SU_DIEM (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_KH NVARCHAR(10) NOT NULL,
    ID_HOADON NVARCHAR(10) NULL,
    SO_DIEM_THAY_DOI INT NOT NULL,
    LY_DO NVARCHAR(200),
    NGAY_TAO DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_LICHSUDIEM_KHACHHANG FOREIGN KEY (ID_KH) REFERENCES KHACHHANG(ID_KH),
    CONSTRAINT FK_LICHSUDIEM_HOADON FOREIGN KEY (ID_HOADON) REFERENCES HOADON(ID_HOADON)
);
GO


-- ADD THÊM ĐỂ SỬ DỤNG XÓA MỀM
ALTER TABLE SAN_PHAM
ADD TRANG_THAI_KD INT NOT NULL DEFAULT 1; -- 1: Kinh doanh, 0: Ngừng
GO
ALTER TABLE KHACHHANG
ADD TRANG_THAI INT NOT NULL DEFAULT 1; -- 1: Hoạt động, 0: Ngừng
GO

--KHI MUỐN KHÔI PHỤC 
UPDATE SAN_PHAM
SET TRANG_THAI_KD = 1 -- 1 = Đang kinh doanh
WHERE ID_SANPHAM = 'SP003'; -- (Thay bằng mã sản phẩm bạn muốn khôi phục)

UPDATE KHACHHANG
SET TRANG_THAI = 1 -- 1 = Đang hoạt động
WHERE ID_KH = 'KH001'; -- (Thay bằng mã khách hàng bạn muốn khôi phục)


---------CHỨC NĂNG CỦA CỬA HÀNG----------------------------------------------------

CREATE PROCEDURE SP_ThemSanPham
    @ID_SANPHAM NVARCHAR(10),
    @TEN_SANPHAM NVARCHAR(100),
    @ID_NHACC NVARCHAR(10),
    @DON_VI NVARCHAR(50),
    @GIA_BAN MONEY,
    @NGAY_SX DATE = NULL,
    @LOAI_HANG NVARCHAR(50) = NULL,
    @NOI_SX NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;-- tắt thống báo message
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Thêm sản phẩm vào bảng sản phẩm
        INSERT INTO SAN_PHAM (
            ID_SANPHAM, TEN_SANPHAM, ID_NHACC, DON_VI, GIA_BAN, NGAY_SX, LOAI_HANG, NOI_SX
        ) VALUES (
            @ID_SANPHAM, @TEN_SANPHAM, @ID_NHACC, @DON_VI, @GIA_BAN, @NGAY_SX, @LOAI_HANG, @NOI_SX
        );
        
        -- Tự động thêm vào kho với số lượng 0
        INSERT INTO KHO_HANG (ID_SANPHAM, SO_LUONG)
        VALUES (@ID_SANPHAM, 0);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR (N'Thêm sản phẩm thất bại', 16, 1);
    END CATCH
END;
GO




	

CREATE PROCEDURE SP_SuaSanPham
    @ID_SANPHAM NVARCHAR(10),             -- Sản phẩm cần sửa
    @TEN_SANPHAM_MOI NVARCHAR(100) = NULL, -- Thông tin mới (để NULL nếu không muốn đổi)
    @ID_NHACC_MOI NVARCHAR(10) = NULL,
    @DON_VI_MOI NVARCHAR(50) = NULL,
    @GIA_BAN_MOI MONEY = NULL,
    @NGAY_SX_MOI DATE = NULL,
    @LOAI_HANG_MOI NVARCHAR(50) = NULL,
    @NOI_SX_MOI NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE SAN_PHAM
    SET 
        -- ISNULL(giá trị mới, giá trị cũ)
        -- Nếu bạn không truyền giá trị mới (để NULL), nó sẽ tự giữ lại giá trị cũ
        TEN_SANPHAM = ISNULL(@TEN_SANPHAM_MOI, TEN_SANPHAM),
        ID_NHACC = ISNULL(@ID_NHACC_MOI, ID_NHACC),
        DON_VI = ISNULL(@DON_VI_MOI, DON_VI),
        GIA_BAN = ISNULL(@GIA_BAN_MOI, GIA_BAN),
        NGAY_SX = ISNULL(@NGAY_SX_MOI, NGAY_SX),
        LOAI_HANG = ISNULL(@LOAI_HANG_MOI, LOAI_HANG),
        NOI_SX = ISNULL(@NOI_SX_MOI, NOI_SX)
    WHERE 
        ID_SANPHAM = @ID_SANPHAM; -- Tìm đúng sản phẩm để sửa
END;
GO


EXEC SP_SuaSanPham
    @ID_SANPHAM = 'SP001',
    @GIA_BAN_MOI = 130000;
    -- Các trường khác không được truyền vào (mặc định là NULL)
    -- nên sẽ được giữ nguyên, không bị thay đổi.







CREATE PROCEDURE SP_XoaSanPham --- xóa theo id sản phẩm
    @ID_SANPHAM NVARCHAR(10)
AS
BEGIN
    -- Đánh dấu là ngừng kinh doanh
    UPDATE SAN_PHAM
    SET TRANG_THAI_KD = 0
    WHERE ID_SANPHAM = @ID_SANPHAM;
    
    -- (Tùy chọn) Đặt số lượng kho về 0 để không bán nữa
    UPDATE KHO_HANG
    SET SO_LUONG = 0
    WHERE ID_SANPHAM = @ID_SANPHAM;
END;
GO

-- Cách sử dụng:
EXEC SP_XoaSanPham @ID_SANPHAM = 'SP001';
GO





--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


--Nhập hàng vô kho
CREATE PROCEDURE SP_NhapKho
    @ID_PHIEUNHAP NVARCHAR(10),
    @ID_SANPHAM NVARCHAR(10),
    @ID_NHACC NVARCHAR(10),
    @SO_LUONGNHAP INT,
    @GIA_NHAP MONEY
AS
BEGIN
    SET NOCOUNT ON;-- tắt thống báo message
    BEGIN TRANSACTION;
    BEGIN TRY
        --Ghi lại lịch sử nhập hàng
        INSERT INTO NHAP_HANG (
            ID_PHIEUNHAP, ID_NHACC, ID_SANPHAM, SO_LUONGNHAP, GIA_NHAP, NGAY_NHAP
        ) VALUES (
            @ID_PHIEUNHAP, @ID_NHACC, @ID_SANPHAM, @SO_LUONGNHAP, @GIA_NHAP, GETDATE()
        );
        
        --Cập nhật số lượng tồn kho
        UPDATE KHO_HANG
        SET SO_LUONG = SO_LUONG + @SO_LUONGNHAP
        WHERE ID_SANPHAM = @ID_SANPHAM;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR (N'Nhập kho thất bại', 16, 1);
    END CATCH
END;
GO



-- Cách sử dụng:
EXEC SP_NhapKho 
    @ID_PHIEUNHAP = 'PN001', 
    @ID_SANPHAM = 'SP001', 
    @ID_NHACC = 'NCC01', 
    @SO_LUONGNHAP = 100, 
    @GIA_NHAP = 80000;
GO



--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

CREATE TYPE T_GioHang AS TABLE (   -- TẠO GIỎ HÀNG NHẰM LƯU DANH SÁCH CỦA NHIỀU SẢN PHẨM VÀ SP_TaoHoaDon  
    ID_SANPHAM NVARCHAR(10),
    SO_LUONGBAN INT,
    DON_GIA MONEY
);
--------------------------------------------------------------------------------------------------------------------

-- Tạo Hóa Đơn và trừ sản phẩm đã bán khỏi kho
CREATE PROCEDURE SP_TaoHoaDon
    @ID_HOADON NVARCHAR(10),
    @ID_KH NVARCHAR(10),
    @HINH_THUC INT,
    @ID_SHIPPER NVARCHAR(10) = NULL,
    @CHIETKHAU MONEY = 0,
    @GioHang T_GioHang READONLY -- Đây là giỏ hàng, SAU KHI TẠO GIỎ HÀNG THÌ GÁN VÔ HÓA ĐƠN ĐỂ LƯU NHIỀU SẢN PHẨM
AS
BEGIN
    SET NOCOUNT ON;-- tắt thống báo message
    BEGIN TRANSACTION;
    BEGIN TRY
        --Tính toán tổng tiền
        DECLARE @TONG_TIEN_SP MONEY;
        DECLARE @TONG_THANH_TOAN MONEY;
        
        SELECT @TONG_TIEN_SP = SUM(SO_LUONGBAN * DON_GIA) FROM @GioHang;
        SET @TONG_THANH_TOAN = @TONG_TIEN_SP - @CHIETKHAU;

        --Tạo hóa đơn
        INSERT INTO HOADON (
            ID_HOADON, ID_KH, NGAY_TAO, CHIETKHAU, 
            TONG_TIEN_SP, TONG_THANH_TOAN, 
            HINH_THUC, TRANG_THAI, ID_SHIPPER
        ) VALUES (
            @ID_HOADON, @ID_KH, GETDATE(), @CHIETKHAU, 
            @TONG_TIEN_SP, @TONG_THANH_TOAN, 
            @HINH_THUC, 1, @ID_SHIPPER -- 1 = Đã xác nhận
        );
        
        --Thêm chi tiết hóa đơn (từ giỏ hàng)
        INSERT INTO DON_HANG (ID_HOADON, ID_SANPHAM, SO_LUONGBAN, DON_GIA)
        SELECT @ID_HOADON, ID_SANPHAM, SO_LUONGBAN, DON_GIA
        FROM @GioHang;
        
        --Trừ khỏi kho (Cập nhật KHO_HANG)
        UPDATE KHO_HANG
        SET SO_LUONG = KHO_HANG.SO_LUONG - gh.SO_LUONGBAN
        FROM KHO_HANG
        JOIN @GioHang gh ON KHO_HANG.ID_SANPHAM = gh.ID_SANPHAM;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RAISERROR (N'Tạo hóa đơn thất bại', 16, 1);
    END CATCH
END;
GO



--------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE SP_ThemKhachHang
    @ID_KH NVARCHAR(10),
    @TEN_KH NVARCHAR(100),
    @SO_DTH VARCHAR(20) = NULL,
    @DIA_CHI NVARCHAR(250) = NULL,
    @THANH_PHO NVARCHAR(50) = NULL,
    @QUOC_GIA NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem ID_KH đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM KHACHHANG WHERE ID_KH = @ID_KH)
    BEGIN
        RAISERROR (N'Mã khách hàng này đã tồn tại.', 16, 1);
        RETURN;
    END

    -- Thêm khách hàng mới
    INSERT INTO KHACHHANG (
        ID_KH, 
        TEN_KH, 
        SO_DTH, 
        DIA_CHI, 
        THANH_PHO, 
        QUOC_GIA,
        DIEM_TICH_LUY, -- Mặc định là 0
        TRANG_THAI     -- Mặc định là 1 (Đang hoạt động)
    )
    VALUES (
        @ID_KH,
        @TEN_KH,
        @SO_DTH,
        @DIA_CHI,
        @THANH_PHO,
        @QUOC_GIA,
        0, -- Điểm tích lũy ban đầu
        1  -- Trạng thái hoạt động
    );
END;
GO

-- Thêm một khách hàng mới
EXEC SP_ThemKhachHang
    @ID_KH = 'KH001',
    @TEN_KH = N'Nguyễn Văn A',
    @SO_DTH = '0909123456',
    @DIA_CHI = N'123 Đường ABC, Phường 1, Quận 1',
    @THANH_PHO = N'TP. Hồ Chí Minh';
	
	



CREATE PROCEDURE SP_SuaKhachHang
    @ID_KH NVARCHAR(10),                 -- Khách hàng cần sửa
    @TEN_KH_MOI NVARCHAR(100) = NULL,    -- Thông tin mới
    @SO_DTH_MOI VARCHAR(20) = NULL,
    @DIA_CHI_MOI NVARCHAR(250) = NULL,
    @THANH_PHO_MOI NVARCHAR(50) = NULL,
    @QUOC_GIA_MOI NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE KHACHHANG
    SET 
        TEN_KH = ISNULL(@TEN_KH_MOI, TEN_KH),
        SO_DTH = ISNULL(@SO_DTH_MOI, SO_DTH),
        DIA_CHI = ISNULL(@DIA_CHI_MOI, DIA_CHI),
        THANH_PHO = ISNULL(@THANH_PHO_MOI, THANH_PHO),
        QUOC_GIA = ISNULL(@QUOC_GIA_MOI, QUOC_GIA)
    WHERE 
        ID_KH = @ID_KH;
END;
GO



EXEC SP_SuaKhachHang
    @ID_KH = 'KH001',
    @SO_DTH_MOI = '0987654321',
    @DIA_CHI_MOI = N'123 Đường mới, Phường 10, Quận 3';
    -- Tên, Thành phố, Quốc gia sẽ được giữ nguyên.




-- Trigger này tự chạy khi TRANG_THAI hóa đơn = 3 (Hoàn thành)
CREATE TRIGGER TG_CongDiemTichLuy
ON HOADON
AFTER UPDATE
AS
BEGIN
    -- Chỉ chạy nếu cột TRANG_THAI bị thay đổi
    IF NOT UPDATE(TRANG_THAI)
        RETURN;

    -- Lấy dữ liệu mới (inserted) và cũ (deleted)
    DECLARE @ID_KH NVARCHAR(10), @ID_HOADON NVARCHAR(10);
    DECLARE @TongTien MONEY, @TrangThaiMoi INT, @TrangThaiCu INT, @DiemThuong INT;

    SELECT 
        @ID_KH = i.ID_KH,
        @ID_HOADON = i.ID_HOADON,
        @TongTien = i.TONG_THANH_TOAN,
        @TrangThaiMoi = i.TRANG_THAI,
        @TrangThaiCu = d.TRANG_THAI
    FROM 
        inserted i
    JOIN 
        deleted d ON i.ID_HOADON = d.ID_HOADON;

    -- Nếu chuyển sang "Hoàn thành" (3) và trước đó chưa hoàn thành
    IF (@TrangThaiMoi = 3 AND @TrangThaiCu <> 3 AND @TongTien > 0)
    BEGIN
        -- Quy tắc: 10,000đ = 1 điểm / thay đổi nếu cần
        SET @DiemThuong = CAST(@TongTien / 10000 AS INT);

        IF (@DiemThuong > 0)
        BEGIN
            UPDATE KHACHHANG
            SET DIEM_TICH_LUY = DIEM_TICH_LUY + @DiemThuong
            WHERE ID_KH = @ID_KH;
            
            INSERT INTO LICH_SU_DIEM (ID_KH, ID_HOADON, SO_DIEM_THAY_DOI, LY_DO)
            VALUES (@ID_KH, @ID_HOADON, @DiemThuong, N'Tích điểm HĐ ' + @ID_HOADON);
        END
    END
END;
GO
-------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE SP_MatHangBanChay
    @TuNgay DATE,
    @DenNgay DATE,
    @TopN INT = 10, -- Lấy top 10 sản phẩm
    @ID_NHACC NVARCHAR(10) = NULL, --Lọc theo nhà cung cấp
    @NoiSX NVARCHAR(100) = NULL    --Lọc theo nơi sản xuất
AS
BEGIN
    SET NOCOUNT ON;-- tắt thống báo message

    SELECT TOP (@TopN)
        sp.ID_SANPHAM,
        sp.TEN_SANPHAM,
        sp.LOAI_HANG,
        ncc.TEN_NHACC,
        sp.NOI_SX,
        SUM(ct.SO_LUONGBAN) AS TongSoLuongBan
    FROM 
        DON_HANG AS ct
    JOIN 
        HOADON AS hd ON ct.ID_HOADON = hd.ID_HOADON
    JOIN 
        SAN_PHAM AS sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
    JOIN
        NHACC AS ncc ON sp.ID_NHACC = ncc.ID_NHACC
    WHERE 
        hd.TRANG_THAI = 3 -- Chỉ tính đơn đã hoàn thành
        AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay
        
        -- Các bộ lọc tùy chọn
        AND (@ID_NHACC IS NULL OR sp.ID_NHACC = @ID_NHACC)
        AND (@NoiSX IS NULL OR sp.NOI_SX = @NoiSX)
    GROUP BY 
        sp.ID_SANPHAM, sp.TEN_SANPHAM, sp.LOAI_HANG, ncc.TEN_NHACC, sp.NOI_SX
    ORDER BY 
        TongSoLuongBan DESC;
END;
GO




--Cách dùng

-- Xem 10 mặt hàng bán chạy nhất Quý 4/2025 (tất cả NCC, mọi nơi SX)
EXEC SP_MatHangBanChay 
    @TuNgay = '2025-10-01', 
    @DenNgay = '2025-12-31';

-- Xem 5 mặt hàng bán chạy nhất Quý 4/2025, CHỈ của nhà cung cấp 'NCC01'
EXEC SP_MatHangBanChay 
    @TuNgay = '2025-10-01', 
    @DenNgay = '2025-12-31', 
    @TopN = 5,
    @ID_NHACC = 'NCC01';

-- Xem 10 mặt hàng bán chạy nhất Quý 4/2025, CHỈ sản xuất tại 'Việt Nam'
EXEC SP_MatHangBanChay 
    @TuNgay = '2025-10-01', 
    @DenNgay = '2025-12-31',
    @NoiSX = N'Việt Nam';
	
-----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE SP_TimKhachHangTheoLoaiHang
    @LoaiHang NVARCHAR(50), -- Loại hàng bạn muốn tìm (ví dụ: N'Tượng trang trí')
    @TuNgay DATE,           -- Ngày bắt đầu
    @DenNgay DATE           -- Ngày kết thúc
AS
BEGIN
    SET NOCOUNT ON;

    -- Dùng DISTINCT để mỗi khách hàng chỉ xuất hiện 1 lần
    SELECT DISTINCT
        kh.ID_KH,
        kh.TEN_KH,
        kh.SO_DTH,
        kh.DIA_CHI
    FROM 
        KHACHHANG AS kh
    JOIN 
        HOADON AS hd ON kh.ID_KH = hd.ID_KH
    JOIN 
        DON_HANG AS ct ON hd.ID_HOADON = ct.ID_HOADON
    JOIN 
        SAN_PHAM AS sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
    WHERE
        hd.TRANG_THAI = 3 -- 1. Chỉ tính các đơn hàng đã hoàn thành
        AND sp.LOAI_HANG = @LoaiHang -- 2. Lọc theo đúng loại hàng
        AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay; -- 3. Lọc trong khoảng thời gian
END;
GO




EXEC SP_TimKhachHangTheoLoaiHang
    @LoaiHang = N'Tượng trang trí',
    @TuNgay = '2025-10-01',
    @DenNgay = '2025-12-31';






CREATE PROCEDURE SP_TimKhachHangTheoThoiGian
    @TuNgay DATE,           -- Ngày bắt đầu
    @DenNgay DATE           -- Ngày kết thúc
AS
BEGIN
    SET NOCOUNT ON;

    -- Dùng DISTINCT để mỗi khách hàng chỉ xuất hiện 1 lần
    SELECT DISTINCT
        kh.ID_KH,
        kh.TEN_KH,
        kh.SO_DTH,
        kh.DIA_CHI
    FROM 
        KHACHHANG AS kh
    JOIN 
        HOADON AS hd ON kh.ID_KH = hd.ID_KH
    WHERE
        hd.TRANG_THAI = 3 -- 1. Chỉ tính các đơn hàng đã hoàn thành
        AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay; -- 2. Lọc trong khoảng thời gian
END;
GO



EXEC SP_TimKhachHangTheoThoiGian
    @TuNgay = '2025-10-01',
    @DenNgay = '2025-12-31';


-----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE SP_MatHangKhongBanDuoc
    @TuNgay DATE,
    @DenNgay DATE,
    @ID_NHACC NVARCHAR(10) = NULL, --Lọc theo nhà cung cấp
    @NoiSX NVARCHAR(100) = NULL    --Lọc theo nơi sản xuất
AS
BEGIN
    SET NOCOUNT ON; -- tắt thống báo message

    SELECT 
        sp.ID_SANPHAM,
        sp.TEN_SANPHAM,
        sp.LOAI_HANG,
        ncc.TEN_NHACC,
        sp.NOI_SX,
        kh.SO_LUONG AS SoLuongTonKho -- Lượng tồn kho hiện tại
    FROM 
        SAN_PHAM AS sp
    JOIN 
        KHO_HANG AS kh ON sp.ID_SANPHAM = kh.ID_SANPHAM
    JOIN
        NHACC AS ncc ON sp.ID_NHACC = ncc.ID_NHACC
    WHERE 
        sp.TRANG_THAI_KD = 1 -- Chỉ kiểm tra hàng đang kinh doanh
        
        -- Các bộ lọc tùy chọn
        AND (@ID_NHACC IS NULL OR sp.ID_NHACC = @ID_NHACC)
        AND (@NoiSX IS NULL OR sp.NOI_SX = @NoiSX)
        
        -- Điều kiện KHÔNG BÁN ĐƯỢC
        AND NOT EXISTS (
            SELECT 1
            FROM DON_HANG ct
            JOIN HOADON hd ON ct.ID_HOADON = hd.ID_HOADON
            WHERE 
                ct.ID_SANPHAM = sp.ID_SANPHAM
                AND hd.TRANG_THAI = 3 -- Đã hoàn thành
                AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay
        )
    ORDER BY
        ncc.TEN_NHACC, sp.TEN_SANPHAM;
END;
GO



--Cách dùng
-- Tìm các mặt hàng không bán được trong Quý 4/2025
EXEC SP_MatHangKhongBanDuoc 
    @TuNgay = '2025-10-01', 
    @DenNgay = '2025-12-31';

-- Tìm các mặt hàng của 'NCC01' sản xuất tại 'Việt Nam' không bán được trong Quý 4
EXEC SP_MatHangKhongBanDuoc 
    @TuNgay = '2025-10-01', 
    @DenNgay = '2025-12-31',
    @ID_NHACC = 'NCC01',
    @NoiSX = N'Việt Nam';





---------------------------------------------------------------------------------------------------------------------------------------------
--Code Báo Cáo (Queries)

-- Yêu cầu: 5 Mặt hàng bán chạy nhất (tháng 10/2025)
SELECT TOP 5
    sp.TEN_SANPHAM,
    sp.LOAI_HANG,
    SUM(ct.SO_LUONGBAN) AS TongSoLuongBan
FROM 
    DON_HANG ct
JOIN 
    HOADON hd ON ct.ID_HOADON = hd.ID_HOADON
JOIN 
    SAN_PHAM sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
WHERE 
    hd.TRANG_THAI = 3 -- Chỉ tính đơn đã hoàn thành
    AND YEAR(hd.NGAY_TAO) = 2025
    AND MONTH(hd.NGAY_TAO) = 10
GROUP BY 
    sp.TEN_SANPHAM, sp.LOAI_HANG
ORDER BY 
    TongSoLuongBan DESC;


-- Yêu cầu: 10 khách hàng có tổng chi tiêu cao nhất 
SELECT TOP 10
    kh.ID_KH,
    kh.TEN_KH,
    SUM(hd.TONG_THANH_TOAN) AS TongChiTieu
FROM 
    KHACHHANG AS kh
JOIN 
    HOADON AS hd ON kh.ID_KH = hd.ID_KH
WHERE 
    hd.TRANG_THAI = 3 -- Chỉ tính các đơn hàng đã hoàn thành
	/*AND MONTH(hd.NGAY_TAO) = month -- Lọc theo tháng
      AND YEAR(hd.NGAY_TAO) = year   -- Lọc theo năm  */ -- thêm vào nếu cần tính cụ thể
GROUP BY 
    kh.ID_KH, kh.TEN_KH -- Nhóm tất cả đơn hàng theo từng khách hàng
ORDER BY 
    TongChiTieu DESC; -- Sắp xếp tổng chi tiêu từ cao xuống thấp
	
	
-- tính khách top1 của cửa hàng
SELECT TOP 1 WITH TIES
    kh.ID_KH,
    kh.TEN_KH,
    hd.ID_HOADON,
    hd.TONG_THANH_TOAN AS GiaTriDonHangLonNhat
FROM 
    HOADON AS hd
JOIN 
    KHACHHANG AS kh ON hd.ID_KH = kh.ID_KH
WHERE 
    hd.TRANG_THAI = 3 -- Chỉ tính các đơn hàng đã hoàn thành
ORDER BY 
    hd.TONG_THANH_TOAN DESC; -- Sắp xếp giá trị đơn hàng từ cao xuống thấp





-- Yêu cầu: Doanh thu theo từng Loại mặt hàng (VD: tháng 10/2025)
SELECT 
    sp.LOAI_HANG,
    SUM(ct.SO_LUONGBAN * ct.DON_GIA) AS DoanhThu
FROM 
    DON_HANG ct
JOIN 
    HOADON hd ON ct.ID_HOADON = hd.ID_HOADON
JOIN 
    SAN_PHAM sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
WHERE 
    hd.TRANG_THAI = 3 -- Chỉ tính đơn đã hoàn thành
    AND YEAR(hd.NGAY_TAO) = 2025
    AND MONTH(hd.NGAY_TAO) = 10
GROUP BY 
    sp.LOAI_HANG
ORDER BY 
    DoanhThu DESC;






-- Yêu cầu: Mặt hàng không bán được (Hàng ế)
SELECT 
    sp.ID_SANPHAM,
    sp.TEN_SANPHAM,
    sp.LOAI_HANG
FROM 
    SAN_PHAM sp
LEFT JOIN 
    KHO_HANG kh ON sp.ID_SANPHAM = kh.ID_SANPHAM
WHERE 
    sp.TRANG_THAI_KD = 1 -- Chỉ ktra hàng đang kinh doanh
    AND NOT EXISTS (
        -- Chưa từng xuất hiện trong bất kỳ hóa đơn nào
        SELECT 1 
        FROM DON_HANG ct 
        WHERE ct.ID_SANPHAM = sp.ID_SANPHAM
    )
ORDER BY 
    sp.LOAI_HANG, sp.TEN_SANPHAM;






--Yêu cầu: Thống kê giá của 1 mặt hàng
SELECT 
    AVG(DON_GIA) AS GiaBanTrungBinh,
    MAX(DON_GIA) AS GiaBanCaoNhat,
    MIN(DON_GIA) AS GiaBanThapNhat
FROM 
    DON_HANG
WHERE 
    ID_SANPHAM = 'ID CẦN TÌM KIẾM'; --NHẬP ID_SANPHAM CẦN THỐNG KÊ
