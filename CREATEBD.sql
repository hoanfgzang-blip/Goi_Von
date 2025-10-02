CREATE DATABASE GoiVon
ON(
	NAME = 'GoiVon_DATA.mdf',
	FILENAME = 'E:\GoiVon\Goi_Von\GoiVon_DATA.mdf',
	SIZE = 5MB,
	MAXSIZE = 500MB,
	FILEGROWTH = 5MB
)
LOG ON 
(
	NAME = 'GoiVon_LOG.ldf',
	FILENAME = 'E:\GoiVon\Goi_Von\GoiVon_LOG.ldf',
	SIZE = 5MB,
	MAXSIZE = 500MB,
	FILEGROWTH = 5MB
)
