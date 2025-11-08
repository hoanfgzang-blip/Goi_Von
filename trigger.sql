-- Khối chuẩn bị: Xóa Trigger cũ trước khi tạo lại (nếu cần)
DROP TRIGGER IF EXISTS TG_CongDiemTichLuy;
DROP TRIGGER IF EXISTS TG_CapNhatNgayGiao_Online;
DROP TRIGGER IF EXISTS TRG_KhoHang_NoNegative;
GO

-- 1. Trigger Tích Điểm Tích Lũy
CREATE TRIGGER TG_CongDiemTichLuy
ON HOADON
AFTER UPDATE
AS
BEGIN
    IF NOT UPDATE(TRANG_THAI) RETURN;

    DECLARE @ID_KH NVARCHAR(10), @ID_HOADON NVARCHAR(10), @TongTien MONEY, @TrangThaiMoi INT, @TrangThaiCu INT, @DiemThuong INT;

    SELECT @ID_KH = i.ID_KH, @ID_HOADON = i.ID_HOADON, @TongTien = i.TONG_THANH_TOAN, @TrangThaiMoi = i.TRANG_THAI, @TrangThaiCu = d.TRANG_THAI
    FROM inserted i JOIN deleted d ON i.ID_HOADON = d.ID_HOADON;

    IF (@TrangThaiMoi = 3 AND @TrangThaiCu <> 3 AND @TongTien > 0)
    BEGIN
        SET @DiemThuong = CAST(@TongTien / 10000 AS INT); -- Tích 1 điểm / 10,000 VNĐ
        IF (@DiemThuong > 0)
        BEGIN
            UPDATE KHACHHANG SET DIEM_TICH_LUY = DIEM_TICH_LUY + @DiemThuong WHERE ID_KH = @ID_KH;
            INSERT INTO LICH_SU_DIEM (ID_KH, ID_HOADON, SO_DIEM_THAY_DOI, LY_DO)
            VALUES (@ID_KH, @ID_HOADON, @DiemThuong, N'Tích điểm HĐ ' + @ID_HOADON);
        END
    END
END;
GO

-- 2. Trigger Cập nhật Ngày Giao Dự kiến và Thực tế
CREATE TRIGGER TG_CapNhatNgayGiao_Online
ON HOADON
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(TRANG_THAI) RETURN;

    -- Cập nhật NGÀY GIAO DỰ KIẾN (Trạng thái 1 -> 2)
    UPDATE hd
    SET hd.NGAY_GIAO_DU_KIEN = DATEADD(day, 3, GETDATE()),
        hd.ID_SHIPPER = ISNULL(hd.ID_SHIPPER, (SELECT TOP 1 ID_SHIPPER FROM SHIPPER))
    FROM HOADON hd JOIN inserted i ON hd.ID_HOADON = i.ID_HOADON JOIN deleted d ON hd.ID_HOADON = d.ID_HOADON
    WHERE i.TRANG_THAI = 2 AND d.TRANG_THAI = 1 AND i.HINH_THUC = 2;

    -- Cập nhật NGÀY GIAO THỰC TẾ (Trạng thái -> 3)
    UPDATE hd
    SET hd.NGAY_GIAO_THUC_TE = GETDATE()
    FROM HOADON hd JOIN inserted i ON hd.ID_HOADON = i.ID_HOADON JOIN deleted d ON hd.ID_HOADON = d.ID_HOADON
    WHERE i.TRANG_THAI = 3 AND d.TRANG_THAI <> 3 AND i.HINH_THUC = 2;
END;
GO

-- 3. Trigger Ngăn chặn Tồn kho Âm
CREATE TRIGGER TRG_KhoHang_NoNegative
ON KHO_HANG
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN KHO_HANG kh ON i.ID_SANPHAM = kh.ID_SANPHAM WHERE kh.SO_LUONG < 0
    )
    BEGIN
        RAISERROR(N'LỖI: Số lượng tồn kho không được phép nhỏ hơn 0. Giao dịch bị hủy.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO