--II. STORED PROCEDURES 
/*
C (Create): Được thực hiện qua các SP như SP_ThemSanPham hoặc SP_TaoHoaDon.

R (Read): Được thực hiện qua các SP báo cáo như SP_InHoaDon hoặc SP_BaoCaoDoanhThu.

U (Update): Được thực hiện qua các SP như SP_SuaSanPham hoặc SP_SuaKhachHang.

D (Delete): Được thực hiện qua SP_XoaSanPham (xóa mềm) hoặc SP_HuyHoaDon (thay đổi trạng thái).
*/

-- 1. SP Thêm Sản Phẩm (CRUD)
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
    SET NOCOUNT ON;
	BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO SAN_PHAM (ID_SANPHAM, TEN_SANPHAM, ID_NHACC, DON_VI, GIA_BAN, NGAY_SX, LOAI_HANG, NOI_SX)
        VALUES (@ID_SANPHAM, @TEN_SANPHAM, @ID_NHACC, @DON_VI, @GIA_BAN, @NGAY_SX, @LOAI_HANG, @NOI_SX);
        INSERT INTO 
			KHO_HANG (ID_SANPHAM, SO_LUONG) VALUES (@ID_SANPHAM, 0);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION; 
        THROW;
    END CATCH
END;
GO

-- 2. SP Sửa Sản Phẩm (CRUD)
CREATE PROCEDURE SP_SuaSanPham
    @ID_SANPHAM NVARCHAR(10),
	@TEN_SANPHAM_MOI NVARCHAR(100) = NULL, 
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
		TEN_SANPHAM = ISNULL(@TEN_SANPHAM_MOI, TEN_SANPHAM), 
		ID_NHACC = ISNULL(@ID_NHACC_MOI, ID_NHACC),
        DON_VI = ISNULL(@DON_VI_MOI, DON_VI), 
		GIA_BAN = ISNULL(@GIA_BAN_MOI, GIA_BAN),
        NGAY_SX = ISNULL(@NGAY_SX_MOI, NGAY_SX), 
		LOAI_HANG = ISNULL(@LOAI_HANG_MOI, LOAI_HANG),
        NOI_SX = ISNULL(@NOI_SX_MOI, NOI_SX)
    WHERE ID_SANPHAM = @ID_SANPHAM;
END;
GO

-- 3. SP Xóa Sản Phẩm (Xóa mềm)
CREATE PROCEDURE SP_XoaSanPham 
	@ID_SANPHAM NVARCHAR(10)
AS
BEGIN
    UPDATE SAN_PHAM 
		SET TRANG_THAI_KD = 0 WHERE ID_SANPHAM = @ID_SANPHAM;
    UPDATE KHO_HANG 
		SET SO_LUONG = 0 WHERE ID_SANPHAM = @ID_SANPHAM;
END;
GO

-- 4. SP Nhập Kho (Nghiệp vụ)
CREATE PROCEDURE SP_NhapKho
    @ID_PHIEUNHAP NVARCHAR(10),
    @ID_NHACC NVARCHAR(10),
    @ID_SANPHAM NVARCHAR(10),
    @SO_LUONGNHAP INT,
    @GIA_NHAP MONEY
AS
BEGIN
    SET NOCOUNT ON; 
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1 Kiểm tra và tạo PHIẾU NHẬP nếu nó chưa tồn tại
        IF NOT EXISTS (SELECT 1 FROM NHAP_HANG WHERE ID_PHIEUNHAP = @ID_PHIEUNHAP)
        BEGIN
            INSERT INTO NHAP_HANG (ID_PHIEUNHAP, ID_NHACC, NGAY_NHAP)
            VALUES (@ID_PHIEUNHAP, @ID_NHACC, GETDATE());
        END
        ELSE
        BEGIN
            --Kiểm tra xem ID_NHACC của phiếu đã có có khớp không
            IF EXISTS (SELECT 1 FROM NHAP_HANG WHERE ID_PHIEUNHAP = @ID_PHIEUNHAP AND ID_NHACC <> @ID_NHACC)
            BEGIN
                RAISERROR(N'Lỗi: Phiếu nhập này đã tồn tại nhưng của nhà cung cấp khác.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- 2 Thêm CHI TIẾT NHẬP HÀNG
        IF EXISTS (SELECT 1 FROM CHI_TIET_NHAP_HANG WHERE ID_PHIEUNHAP = @ID_PHIEUNHAP AND ID_SANPHAM = @ID_SANPHAM)
        BEGIN
            -- Sản phẩm đã có, cập nhật số lượng/giá
            UPDATE CHI_TIET_NHAP_HANG
            SET SO_LUONGNHAP = SO_LUONGNHAP + @SO_LUONGNHAP, -- Cộng dồn
                GIA_NHAP = @GIA_NHAP -- Lấy giá mới
            WHERE ID_PHIEUNHAP = @ID_PHIEUNHAP AND ID_SANPHAM = @ID_SANPHAM;
        END
        ELSE
        BEGIN
            -- Sản phẩm chưa có, thêm mới
            INSERT INTO CHI_TIET_NHAP_HANG (ID_PHIEUNHAP, ID_SANPHAM, SO_LUONGNHAP, GIA_NHAP)
            VALUES (@ID_PHIEUNHAP, @ID_SANPHAM, @SO_LUONGNHAP, @GIA_NHAP);
        END

        -- 3 Cập nhật KHO HÀNG
        UPDATE KHO_HANG 
        SET SO_LUONG = SO_LUONG + @SO_LUONGNHAP 
        WHERE ID_SANPHAM = @ID_SANPHAM;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
        THROW; 
    END CATCH
END;
GO

-- 5. SP Tạo Hóa Đơn (Cốt lõi bán hàng, tích hợp trừ điểm)
CREATE PROCEDURE SP_TaoHoaDon
    @ID_HOADON NVARCHAR(10),
	@ID_KH NVARCHAR(10), 
	@HINH_THUC INT,
	@ID_SHIPPER NVARCHAR(10) = NULL,
    @CHIETKHAU MONEY = 0,
	@DIEM_SU_DUNG INT = 0,
    @GioHang T_GioHang READONLY
AS
BEGIN
    SET NOCOUNT ON; 
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @TONG_TIEN_SP MONEY, @TONG_THANH_TOAN MONEY;
        --1 Thêm logic quy đổi điểm
        DECLARE @TienDoiTuDiem MONEY = 0;
        DECLARE @TyLeQuyDoi MONEY = 1000; -- QUAN TRỌNG: 1 điểm = 1000 VNĐ (Bạn có thể thay đổi tỷ lệ này)

        SET @TienDoiTuDiem = @DIEM_SU_DUNG * @TyLeQuyDoi;

        -- KIỂM TRA ĐIỂM TỒN KHO
        IF @DIEM_SU_DUNG > 0 AND @DIEM_SU_DUNG > (SELECT DIEM_TICH_LUY FROM KHACHHANG WHERE ID_KH = @ID_KH)
        BEGIN RAISERROR (N'Lỗi: Số điểm sử dụng vượt quá điểm tích lũy hiện có.', 16, 1); RETURN; END

        SELECT @TONG_TIEN_SP = SUM(SO_LUONGBAN * DON_GIA) FROM @GioHang;

        --2 Trừ tiền quy đổi vào tổng thanh toán
        SET @TONG_THANH_TOAN = @TONG_TIEN_SP - @CHIETKHAU - @TienDoiTuDiem;

        -- Đảm bảo tổng thanh toán không bao giờ âm
        IF @TONG_THANH_TOAN < 0 SET @TONG_THANH_TOAN = 0;

        INSERT INTO HOADON (ID_HOADON, ID_KH, NGAY_TAO, CHIETKHAU, TONG_TIEN_SP, TONG_THANH_TOAN, HINH_THUC, TRANG_THAI, ID_SHIPPER)
        VALUES (@ID_HOADON, @ID_KH, GETDATE(), @CHIETKHAU, @TONG_TIEN_SP, @TONG_THANH_TOAN, @HINH_THUC, 1, @ID_SHIPPER);

        INSERT INTO DON_HANG (ID_HOADON, ID_SANPHAM, SO_LUONGBAN, DON_GIA) SELECT @ID_HOADON, ID_SANPHAM, SO_LUONGBAN, DON_GIA FROM @GioHang;
        UPDATE KHO_HANG SET SO_LUONG = KHO_HANG.SO_LUONG - gh.SO_LUONGBAN FROM KHO_HANG JOIN @GioHang gh ON KHO_HANG.ID_SANPHAM = gh.ID_SANPHAM;

        -- Trừ điểm và ghi log sử dụng điểm
        IF @DIEM_SU_DUNG > 0
        BEGIN
            UPDATE KHACHHANG SET DIEM_TICH_LUY = DIEM_TICH_LUY - @DIEM_SU_DUNG WHERE ID_KH = @ID_KH;
            INSERT INTO LICH_SU_DIEM (ID_KH, ID_HOADON, SO_DIEM_THAY_DOI, LY_DO)
            VALUES (@ID_KH, @ID_HOADON, -@DIEM_SU_DUNG, N'Sử dụng điểm cho HĐ ' + @ID_HOADON);
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
        THROW;
    END CATCH
END;
GO

-- 6. SP Hủy Hóa Đơn (Hoàn tác)
CREATE PROCEDURE SP_HuyHoaDon 
    @ID_HOADON NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON; BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @ID_KH NVARCHAR(10);
        SELECT @ID_KH = ID_KH FROM HOADON WHERE ID_HOADON = @ID_HOADON;

        IF (SELECT TRANG_THAI FROM HOADON WHERE ID_HOADON = @ID_HOADON) = 4 BEGIN RAISERROR (N'Hóa đơn đã bị hủy.', 16, 1); RETURN; END

        -- Hoàn lại tồn kho
        UPDATE kh 
        SET SO_LUONG = kh.SO_LUONG + dh.SO_LUONGBAN
        FROM KHO_HANG kh 
        JOIN DON_HANG dh ON kh.ID_SANPHAM = dh.ID_SANPHAM 
        WHERE dh.ID_HOADON = @ID_HOADON;

        -- Hoàn tác điểm đã TÍCH LŨY (điểm dương)
        DECLARE @DiemDaTich INT = ISNULL((SELECT SUM(SO_DIEM_THAY_DOI) FROM LICH_SU_DIEM WHERE ID_HOADON = @ID_HOADON AND SO_DIEM_THAY_DOI > 0), 0);
        IF @DiemDaTich > 0
        BEGIN
            UPDATE KHACHHANG SET DIEM_TICH_LUY = DIEM_TICH_LUY - @DiemDaTich WHERE ID_KH = @ID_KH;
            INSERT INTO LICH_SU_DIEM (ID_KH, ID_HOADON, SO_DIEM_THAY_DOI, LY_DO)
            VALUES (@ID_KH, @ID_HOADON, -@DiemDaTich, N'Hoàn tác điểm TÍCH LŨY do Hủy HĐ ' + @ID_HOADON);
        END
        
        --Hoàn tác điểm đã SỬ DỤNG (điểm âm)
        DECLARE @DiemDaSuDung INT = ISNULL((SELECT SUM(SO_DIEM_THAY_DOI) FROM LICH_SU_DIEM WHERE ID_HOADON = @ID_HOADON AND SO_DIEM_THAY_DOI < 0), 0);
        IF @DiemDaSuDung < 0
        BEGIN
            DECLARE @DiemHoanTra INT = ABS(@DiemDaSuDung); -- Chuyển số âm thành dương
            
            UPDATE KHACHHANG SET DIEM_TICH_LUY = DIEM_TICH_LUY + @DiemHoanTra WHERE ID_KH = @ID_KH;
            
            INSERT INTO LICH_SU_DIEM (ID_KH, ID_HOADON, SO_DIEM_THAY_DO	I, LY_DO)
            VALUES (@ID_KH, @ID_HOADON, @DiemHoanTra, N'Hoàn tác điểm SỬ DỤNG do Hủy HĐ ' + @ID_HOADON);
        END
        
        -- Cập nhật trạng thái
        UPDATE HOADON SET TRANG_THAI = 4 WHERE ID_HOADON = @ID_HOADON;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW; END CATCH
END;
GO

-- 7. SP Báo cáo Tồn kho Thấp (Báo cáo)
CREATE PROCEDURE SP_CanhBao_HangTonThap
AS
BEGIN
    SET NOCOUNT ON;
    SELECT sp.ID_SANPHAM, sp.TEN_SANPHAM, kh.SO_LUONG AS SoLuongTonKho, kh.MUC_CANH_BAO
    FROM KHO_HANG kh JOIN SAN_PHAM sp ON kh.ID_SANPHAM = sp.ID_SANPHAM
    WHERE kh.SO_LUONG <= kh.MUC_CANH_BAO AND sp.TRANG_THAI_KD = 1
    ORDER BY kh.SO_LUONG ASC;
END;
GO

-- 8. SP_ThemKhachHang (CRUD)
CREATE PROCEDURE SP_ThemKhachHang
    @ID_KH NVARCHAR(10), @TEN_KH NVARCHAR(100), @SO_DTH VARCHAR(20) = NULL,
    @DIA_CHI NVARCHAR(250) = NULL, @THANH_PHO NVARCHAR(50) = NULL, @QUOC_GIA NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM KHACHHANG WHERE ID_KH = @ID_KH)
    BEGIN RAISERROR (N'Mã khách hàng này đã tồn tại.', 16, 1); RETURN; END
    INSERT INTO KHACHHANG (ID_KH, TEN_KH, SO_DTH, DIA_CHI, THANH_PHO, QUOC_GIA, DIEM_TICH_LUY, TRANG_THAI)
    VALUES (@ID_KH, @TEN_KH, @SO_DTH, @DIA_CHI, @THANH_PHO, @QUOC_GIA, 0, 1);
END;
GO

-- 9. SP Sửa Khách Hàng (CRUD)
CREATE PROCEDURE SP_SuaKhachHang
    @ID_KH NVARCHAR(10), @TEN_KH_MOI NVARCHAR(100) = NULL, @SO_DTH_MOI VARCHAR(20) = NULL,
    @DIA_CHI_MOI NVARCHAR(250) = NULL, @THANH_PHO_MOI NVARCHAR(50) = NULL, @QUOC_GIA_MOI NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE KHACHHANG
    SET TEN_KH = ISNULL(@TEN_KH_MOI, TEN_KH), SO_DTH = ISNULL(@SO_DTH_MOI, SO_DTH),
        DIA_CHI = ISNULL(@DIA_CHI_MOI, DIA_CHI), THANH_PHO = ISNULL(@THANH_PHO_MOI, THANH_PHO),
        QUOC_GIA = ISNULL(@QUOC_GIA_MOI, QUOC_GIA)
    WHERE ID_KH = @ID_KH;
END;
GO

-- 10. SP Xóa Mềm Khách Hàng (CRUD)
CREATE PROCEDURE SP_XoaMemKhachHang
    @ID_KH NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE ID_KH = @ID_KH)
    BEGIN
        RAISERROR (N'Lỗi: Mã khách hàng không tồn tại.', 16, 1);
        RETURN;
    END

    -- Cập nhật trạng thái thành 0 (Ngừng hoạt động/Xóa mềm)
    UPDATE KHACHHANG
    SET TRANG_THAI = 0
    WHERE ID_KH = @ID_KH;
END;
GO

-- 11. SP Báo cáo Doanh thu Linh hoạt (Báo cáo)
CREATE PROCEDURE SP_BaoCaoDoanhThu
    @LoaiBaoCao NVARCHAR(10) = 'LUYKE', 
    @Nam INT = NULL,
    @Thang INT = NULL 
AS
BEGIN
    SET NOCOUNT ON; 
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX) = N'@Nam INT, @Thang INT'; -- Khai báo tham số cho sp_executesql

    -- 1. Xây dựng lệnh SELECT chính dựa trên @LoaiBaoCao
    IF @LoaiBaoCao = 'NAM'
    BEGIN
        SET @SQL = N'
            SELECT YEAR(NGAY_TAO) AS Nam, SUM(TONG_THANH_TOAN) AS TongDoanhThu
            FROM DON_HOAN_THANH
            GROUP BY YEAR(NGAY_TAO) ORDER BY Nam DESC;';
    END
    ELSE IF @LoaiBaoCao = 'THANG'
    BEGIN
        SET @SQL = N'
            SELECT YEAR(NGAY_TAO) AS Nam, MONTH(NGAY_TAO) AS Thang, SUM(TONG_THANH_TOAN) AS TongDoanhThu
            FROM DON_HOAN_THANH
            GROUP BY YEAR(NGAY_TAO), MONTH(NGAY_TAO) ORDER BY Nam DESC, Thang DESC;';
    END
    ELSE IF @LoaiBaoCao = 'TUAN'
    BEGIN
        SET @SQL = N'
            SELECT YEAR(NGAY_TAO) AS Nam, DATEPART(wk, NGAY_TAO) AS Tuan, MIN(NGAY_TAO) AS NgayBatDauTuan, 
                SUM(TONG_THANH_TOAN) AS TongDoanhThu
            FROM DON_HOAN_THANH 
            GROUP BY YEAR(NGAY_TAO), DATEPART(wk, NGAY_TAO) ORDER BY Nam DESC, Tuan DESC;';
    END
    ELSE -- LUY KE (Mặc định)
    BEGIN
        SET @SQL = N'
            SELECT SUM(TONG_THANH_TOAN) AS TongDoanhThuLuyKe
            FROM DON_HOAN_THANH;';
    END

    -- 2. Gói CTE (Bảng tạm) và lệnh SELECT đã chọn vào một lệnh EXECUTE chung
    SET @SQL = N'WITH DON_HOAN_THANH AS (
        SELECT NGAY_TAO, TONG_THANH_TOAN FROM HOADON
        WHERE TRANG_THAI = 3 
            AND (@Nam IS NULL OR YEAR(NGAY_TAO) = @Nam)
            AND (@Thang IS NULL OR MONTH(NGAY_TAO) = @Thang) 
    ) ' + @SQL;

    -- 3. Thực thi lệnh SQL động
    EXEC sp_executesql @SQL, @Params, @Nam, @Thang;

END;
GO

-- 12. SP Báo cáo Mặt hàng Bán chạy (Báo cáo)
CREATE PROCEDURE SP_MatHangBanChay
    @TuNgay DATE, @DenNgay DATE, @TopN INT = 10, @ID_NHACC NVARCHAR(10) = NULL, @NoiSX NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@TopN) sp.ID_SANPHAM, sp.TEN_SANPHAM, sp.LOAI_HANG, ncc.TEN_NHACC, sp.NOI_SX,
        SUM(ct.SO_LUONGBAN) AS TongSoLuongBan
    FROM DON_HANG AS ct
    JOIN HOADON AS hd ON ct.ID_HOADON = hd.ID_HOADON
    JOIN SAN_PHAM AS sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
    JOIN NHACC AS ncc ON sp.ID_NHACC = ncc.ID_NHACC
    WHERE hd.TRANG_THAI = 3 AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay
        AND (@ID_NHACC IS NULL OR sp.ID_NHACC = @ID_NHACC)
        AND (@NoiSX IS NULL OR sp.NOI_SX = @NoiSX)
    GROUP BY sp.ID_SANPHAM, sp.TEN_SANPHAM, sp.LOAI_HANG, ncc.TEN_NHACC, sp.NOI_SX
    ORDER BY TongSoLuongBan DESC;
END;
GO

-- 13. SP Báo cáo Mặt hàng Không bán được (Báo cáo)
CREATE PROCEDURE SP_MatHangKhongBanDuoc
    @TuNgay DATE, @DenNgay DATE, @ID_NHACC NVARCHAR(10) = NULL, @NoiSX NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        sp.ID_SANPHAM, sp.TEN_SANPHAM, sp.LOAI_HANG, ncc.TEN_NHACC, sp.NOI_SX, kh.SO_LUONG AS SoLuongTonKho
    FROM  SAN_PHAM AS sp
    JOIN  KHO_HANG AS kh ON sp.ID_SANPHAM = kh.ID_SANPHAM
    JOIN  NHACC AS ncc ON sp.ID_NHACC = ncc.ID_NHACC
    WHERE 
        sp.TRANG_THAI_KD = 1
        AND (@ID_NHACC IS NULL OR sp.ID_NHACC = @ID_NHACC)
        AND (@NoiSX IS NULL OR sp.NOI_SX = @NoiSX)
        AND NOT EXISTS (
            SELECT 1 FROM DON_HANG ct
            JOIN HOADON hd ON ct.ID_HOADON = hd.ID_HOADON
            WHERE 
                ct.ID_SANPHAM = sp.ID_SANPHAM
                AND hd.TRANG_THAI = 3
                AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay
        )
    ORDER BY ncc.TEN_NHACC, sp.TEN_SANPHAM;
END;
GO

-- 14. SP Báo cáo Doanh thu theo Khách hàng (Báo cáo)
CREATE PROCEDURE SP_BaoCaoDoanhThuTheoKH
    @TuNgay DATE = NULL, @DenNgay DATE = NULL, @TopN INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@TopN)
        kh.ID_KH, kh.TEN_KH,
        SUM(hd.TONG_THANH_TOAN) AS TongChiTieu
    FROM KHACHHANG AS kh JOIN HOADON AS hd ON kh.ID_KH = hd.ID_KH
    WHERE 
        hd.TRANG_THAI = 3
        AND (@TuNgay IS NULL OR hd.NGAY_TAO >= @TuNgay)
        AND (@DenNgay IS NULL OR hd.NGAY_TAO <= @DenNgay)
    GROUP BY kh.ID_KH, kh.TEN_KH
    ORDER BY TongChiTieu DESC;
END;
GO

-- 15. SP Tìm Khách Hàng Theo Loại Hàng (Báo cáo)
CREATE PROCEDURE SP_TimKhachHangTheoLoaiHang
    @LoaiHang NVARCHAR(50), @TuNgay DATE, @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT kh.ID_KH, kh.TEN_KH, kh.SO_DTH, kh.DIA_CHI
    FROM KHACHHANG AS kh JOIN HOADON AS hd ON kh.ID_KH = hd.ID_KH
    JOIN DON_HANG AS ct ON hd.ID_HOADON = ct.ID_HOADON
    JOIN SAN_PHAM AS sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
    WHERE hd.TRANG_THAI = 3 AND sp.LOAI_HANG = @LoaiHang AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay;
END;
GO

-- 16. SP Tìm Khách Hàng Theo Thời Gian (Báo cáo)
CREATE PROCEDURE SP_TimKhachHangTheoThoiGian
    @TuNgay DATE, @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT kh.ID_KH, kh.TEN_KH, kh.SO_DTH, kh.DIA_CHI
    FROM KHACHHANG AS kh JOIN HOADON AS hd ON kh.ID_KH = hd.ID_KH
    WHERE hd.TRANG_THAI = 3 AND hd.NGAY_TAO BETWEEN @TuNgay AND @DenNgay;
END;
GO

-- 17. SP In Hóa Đơn (Báo cáo)
CREATE PROCEDURE SP_InHoaDon
    @ID_HOADON NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT hd.ID_HOADON, hd.NGAY_TAO, hd.CHIETKHAU, hd.TONG_TIEN_SP, hd.TONG_THANH_TOAN,
        hd.HINH_THUC, hd.TRANG_THAI, hd.NGAY_GIAO_DU_KIEN, hd.NGAY_GIAO_THUC_TE,
        kh.TEN_KH, kh.SO_DTH AS DTH_KH, kh.DIA_CHI AS DiaChi_KH, s.TEN_HANG_SHIPPER
    FROM HOADON hd JOIN KHACHHANG kh ON hd.ID_KH = kh.ID_KH
    LEFT JOIN SHIPPER s ON hd.ID_SHIPPER = s.ID_SHIPPER
    WHERE hd.ID_HOADON = @ID_HOADON;

    SELECT ct.ID_SANPHAM, sp.TEN_SANPHAM, ct.SO_LUONGBAN, ct.DON_GIA,
        (ct.SO_LUONGBAN * ct.DON_GIA) AS Thanh_Tien
    FROM DON_HANG ct JOIN SAN_PHAM sp ON ct.ID_SANPHAM = sp.ID_SANPHAM
    WHERE ct.ID_HOADON = @ID_HOADON;
END;
GO



--========================================================================================================================================================
-- CHƯA UPDATE BÁO CÁO
--========================================================================================================================================================


--18. SP Báo Cáo Số Lượng Khách Hàng
CREATE PROCEDURE SP_BaoCaoSoLuongKhachHang
    @LoaiBaoCao NVARCHAR(10) = 'TONG', -- Tham số: 'TUAN', 'THANG', 'NAM', 'TONG'
    @Nam INT = NULL,
    @Thang INT = NULL,
    @Tuan INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- TÍNH TỔNG SỐ KHÁCH HÀNG (đang hoạt động) - Trường hợp này đơn giản, không cần CTE/SQL động
    IF @LoaiBaoCao = 'TONG'
    BEGIN
        SELECT COUNT(ID_KH) AS TongSoKhachHang
        FROM KHACHHANG
        WHERE TRANG_THAI = 1;
        RETURN; -- Kết thúc SP ở đây nếu chỉ cần tổng
    END

    -- CÁC BÁO CÁO THEO HOẠT ĐỘNG MUA HÀNG (Dùng SQL động)
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Params NVARCHAR(MAX) = N'@Nam INT, @Thang INT, @Tuan INT'; -- Tham số cho SQL động

    -- Xây dựng phần SELECT chính dựa trên @LoaiBaoCao
    IF @LoaiBaoCao = 'NAM'
    BEGIN
        SET @SQL = N'
            SELECT
                YEAR(NGAY_TAO) AS Nam,
                COUNT(DISTINCT ID_KH) AS SoLuongKhachMuaHang
            FROM DON_HOAN_THANH_THEO_TG
            GROUP BY YEAR(NGAY_TAO)
            ORDER BY Nam DESC;';
    END
    ELSE IF @LoaiBaoCao = 'THANG'
    BEGIN
        SET @SQL = N'
            SELECT
                YEAR(NGAY_TAO) AS Nam,
                MONTH(NGAY_TAO) AS Thang,
                COUNT(DISTINCT ID_KH) AS SoLuongKhachMuaHang
            FROM DON_HOAN_THANH_THEO_TG
            GROUP BY YEAR(NGAY_TAO), MONTH(NGAY_TAO)
            ORDER BY Nam DESC, Thang DESC;';
    END
    ELSE IF @LoaiBaoCao = 'TUAN'
    BEGIN
        SET @SQL = N'
            SELECT
                YEAR(NGAY_TAO) AS Nam,
                DATEPART(wk, NGAY_TAO) AS Tuan,
                MIN(NGAY_TAO) AS NgayBatDauTuan,
                COUNT(DISTINCT ID_KH) AS SoLuongKhachMuaHang
            FROM DON_HOAN_THANH_THEO_TG
            GROUP BY YEAR(NGAY_TAO), DATEPART(wk, NGAY_TAO)
            ORDER BY Nam DESC, Tuan DESC;';
    END
    ELSE -- Nếu @LoaiBaoCao không hợp lệ (ngoài 'TONG'), không trả về gì hoặc báo lỗi (tùy chọn)
    BEGIN
        RETURN;
    END

    -- Gói CTE và lệnh SELECT vào SQL động
    SET @SQL = N'WITH DON_HOAN_THANH_THEO_TG AS (
        SELECT
            hd.ID_KH,
            hd.NGAY_TAO
        FROM HOADON hd
        WHERE hd.TRANG_THAI = 3
            AND (@Nam IS NULL OR YEAR(hd.NGAY_TAO) = @Nam)
            AND (@Thang IS NULL OR MONTH(hd.NGAY_TAO) = @Thang)
            AND (@Tuan IS NULL OR DATEPART(wk, hd.NGAY_TAO) = @Tuan)
    ) ' + @SQL;

    -- Thực thi SQL động
    EXEC sp_executesql @SQL, @Params, @Nam, @Thang, @Tuan;

END;
GO


--19. SP Khôi phục Khách hàng
CREATE PROCEDURE SP_KhoiPhucKhachHang
    @ID_KH NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE KHACHHANG
    SET TRANG_THAI = 1 -- Đặt lại trạng thái hoạt động
    WHERE ID_KH = @ID_KH AND TRANG_THAI = 0; -- Chỉ khôi phục nếu đang bị xóa mềm
END;
GO

--20. SP Khôi phục Sản phẩm
CREATE PROCEDURE SP_KhoiPhucSanPham
    @ID_SANPHAM NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE SAN_PHAM
    SET TRANG_THAI_KD = 1 -- Đặt lại trạng thái kinh doanh
    WHERE ID_SANPHAM = @ID_SANPHAM AND TRANG_THAI_KD = 0;
END;
GO


--21. SP Báo cáo số lượng đơn hàng
CREATE PROCEDURE SP_DemTongHoaDon
    @DonHang BIT = 0 --   0 = Đếm tất cả các loại đơn, 1 = Chỉ đếm đơn đã hoàn thành
AS
BEGIN
    SET NOCOUNT ON;

    IF @DonHang = 1
    BEGIN
        -- Chỉ đếm đơn đã hoàn thành (TRANG_THAI = 3)
        SELECT COUNT(ID_HOADON) AS TongSoHoaDon
        FROM HOADON
        WHERE TRANG_THAI = 3;
    END
    ELSE
    BEGIN
        -- Đếm tất cả hóa đơn (bất kể trạng thái)
        SELECT COUNT(ID_HOADON) AS TongSoHoaDon
        FROM HOADON;
    END
END;
GO