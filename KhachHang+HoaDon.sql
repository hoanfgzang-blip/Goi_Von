CREATE DATABASE ban_hang_db;
GO

USE ban_hang_db;
GO

CREATE TABLE KhachHang (
    IdKhachHang INT IDENTITY(1,1) NOT NULL,
    TenKhachHang NVARCHAR(100) NOT NULL,
	Email NVARCHAR (250) NULL,
    DiaChi NVARCHAR(250) NULL,
    SDT VARCHAR(20) NULL,
    NgayTao DATETIME2 DEFAULT GETDATE(),

    CONSTRAINT PK_KhachHang PRIMARY KEY CLUSTERED (IdKhachHang),
    CONSTRAINT UQ_KhachHang_SDT UNIQUE (SDT),
);
GO



CREATE TABLE DonDatHang (
    IdDonHang INT IDENTITY(1,1) NOT NULL,
    IdKhachHang INT NOT NULL,
    NgayDatHang DATETIME2 DEFAULT GETDATE(),
    LoaiDonHang INT NOT NULL DEFAULT 1, -- 1: Online, 2: Offline
    TongTien DECIMAL(18,0) DEFAULT 0, 
    TrangThai INT NOT NULL DEFAULT 1,  -- 1: Mới, 2: Đã xác nhận, 3: Hoàn thành, 4: Hủy
	
	

    CONSTRAINT PK_DonDatHang PRIMARY KEY CLUSTERED (IdDonHang),
    CONSTRAINT FK_DonDatHang_KhachHang FOREIGN KEY (IdKhachHang) REFERENCES KhachHang(IdKhachHang)
);
GO

CREATE TABLE HoaDon (
    IDHoaDon INT IDENTITY(1,1) NOT NULL,
	IdDonHang INT NOT NULL,
    NgayTao DATETIME2 DEFAULT GETDATE(),
	NgayThanhToan DATETIME2 NUll,
	SoLuong INT NOT NULL DEFAULT 1,
    GiaBan DECIMAL(30,0) NOT NULL,
    TongTien AS (GiaBan * SoLuong),

    CONSTRAINT PK_HoaDon PRIMARY KEY CLUSTERED (IDHoaDon),
    CONSTRAINT FK_HoaDon_DonDatHang FOREIGN KEY (IdDonHang) REFERENCES DonDatHang(IdDonHang),
    CONSTRAINT CK_HoaDon_SoLuong CHECK (SoLuong > 0),
    CONSTRAINT CK_HoaDon_GiaBan CHECK (GiaBan >= 0)
);
GO
