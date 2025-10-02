CREATE TABLE KHACHHANG (
    makh VARCHAR(10) PRIMARY KEY,
    tenkh VARCHAR(100),
    diachi VARCHAR(200)
);

CREATE TABLE SANPHAM (
    masp VARCHAR(10) PRIMARY KEY,
    tensp VARCHAR(100),
    mausac VARCHAR(50),
    dongia DECIMAL(18,2)
);

CREATE TABLE HOADON (
    mahd VARCHAR(10) PRIMARY KEY,
    ngaylap DATE,
    makh VARCHAR(10),
    masp VARCHAR(10),
    soluong INT,
    FOREIGN KEY (makh) REFERENCES KHACHHANG(makh),
    FOREIGN KEY (masp) REFERENCES SANPHAM(masp)
);

SELECT 
    SANPHAM.masp, 
    SANPHAM.tensp, 
    SANPHAM.mausac
FROM 
    HOADON
    JOIN SANPHAM ON HOADON.masp = SANPHAM.masp
WHERE 
    HOADON.makh = 'KH001';