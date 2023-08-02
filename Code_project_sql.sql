--- Tạo database tên project
create database project
go

--- Truy cập database project 
use project
go

--- import bảng Invistico_Airline 


--- Thêm cột customer_id, customer_id tự tăng dần ( bắt đầu từ 1 với bước nhảy là 1 )
alter table Invistico_Airline
add customer_id int identity(1,1)
go

--- Tách thông tin của khách hàng ra một bảng mới, bảng cũ chỉ bao gồm các feedback của khách hàng
select Invistico_Airline.customer_id,
Invistico_Airline.Gender,
Invistico_Airline.[Customer Type],
Invistico_Airline.Age,
Invistico_Airline.[Type of Travel],
Invistico_Airline.Class,
Invistico_Airline.[Flight Distance]
into information_customer
from Invistico_Airline

--- Xóa các cột chứa thông tin khách hàng ở bảng Invistico_Airline
alter table Invistico_Airline
drop column Gender, [Customer Type], Age, [Type of Travel], Class, [Flight Distance]


--- Khám phá dữ liệu
select distinct dbo.Invistico_Airline.satisfaction as customer_reactions 
from Invistico_Airline

select count(Invistico_Airline.satisfaction) as the_number_dissatisfied_customers 
from Invistico_Airline
where satisfaction = 'dissatisfied'

select count(Invistico_Airline.satisfaction) as the_number_satisfied_customers 
from Invistico_Airline
where satisfaction = 'satisfied'

select distinct dbo.Invistico_Airline.[Customer Type] as Customer_Type 
from Invistico_Airline


--- Đếm số khách không hài lòng theo từng loại hình du lịch
select information_customer.[Type of Travel], count(Invistico_Airline.satisfaction)  as Number_of_dissatisfied_customers
from information_customer
left join Invistico_Airline on information_customer.customer_id = Invistico_Airline.customer_id
where satisfaction = 'dissatisfied'
group by information_customer.[Type of Travel]


--- Đếm số khách không hài lòng theo từng hạng bay
select  information_customer.Class, count(Invistico_Airline.satisfaction) as Number_of_dissatisfied_customers 
from information_customer
left join Invistico_Airline on information_customer.customer_id = Invistico_Airline.customer_id
where satisfaction = 'dissatisfied'
group by information_customer.Class


--- Nhóm cột tuổi thành các nhóm tương ứng và đếm số lượng khách theo từng nhóm vừa tạo
with age_group as (
	select dbo.information_customer.Age,
	case 
		 when Age <= 12 then 'young children'
         when Age > 12 AND Age < 18 then 'teenager'
         when Age >= 18 AND Age < 25 then 'young person'
         when Age >= 25 AND Age <= 39 then 'young adults'
         when Age >= 40 AND Age < 65 then 'middle-aged adults'
		 else 'senior citizens'
		end as age_classification
	from information_customer)
select age_classification, count(*) as count_of_age_classification
from age_group
group by age_classification


--- Nhóm tuổi có số lượng lớn nhất 
with age_group as (
	select dbo.information_customer.Age,
	case 
		 when Age <= 12 then 'young children'
         when Age > 12 AND Age < 18 then 'teenager'
         when Age >= 18 AND Age < 25 then 'young person'
         when Age >= 25 AND Age <= 39 then 'young adults'
         when Age >= 40 AND Age < 65 then 'middle-aged adults'
		 else 'senior citizens'
		end as age_classification
	from information_customer)
select top 1 age_classification, count_of_age_classification AS max_count 
from(
	select age_classification, count(*) as count_of_age_classification
	from age_group
	group by age_classification) as GroupCounts
order by count_of_age_classification desc


--- Lọc ra nhóm có số lượng khách không hài lòng dựa trên các thông tin như nhóm tuổi, hạng bay
with group1 as (
	select Invistico_Airline.satisfaction, information_customer.class, information_customer.age,
	case 
		 when information_customer.Age <= 12 then 'young children'
         when information_customer.Age > 12 AND information_customer.Age < 18 then 'teenager'
         when information_customer.Age >= 18 AND information_customer.Age < 25 then 'young person'
         when information_customer.Age >= 25 AND information_customer.Age <= 39 then 'young adults'
         when information_customer.Age >= 40 AND information_customer.Age < 65 then 'middle-aged adults'
		 else 'senior citizens'
		end as age_classification
	from information_customer
	left join Invistico_Airline on information_customer.customer_id = Invistico_Airline.customer_id)
select top 1 group1.satisfaction, age_classification, group1.class, count(*) as Number_of_dissatisfied_customers
from group1
where group1.satisfaction = 'dissatisfied' and group1.class = 'business'
group by group1.satisfaction, age_classification, group1.class
order by count(*) desc


---Tạo view bao gồm các khách hàng không hài lòng 
create view dissatisfied_customer as
select information_customer.customer_id,
Invistico_Airline.satisfaction,
information_customer.Age,
information_customer.Gender,
information_customer.Class,
information_customer.[Customer Type],
information_customer.[Flight Distance]
from information_customer
left join Invistico_Airline on information_customer.customer_id = Invistico_Airline.customer_id
where satisfaction = 'dissatisfied'



---Tạo function trả về satisfation của khách hàng xác định theo customer_id
create function feedback_from_each_customer (
@customer_id1 int )
returns varchar(20)
as 
begin
declare @satisfaction1 varchar(20)
select @satisfaction1= satisfaction from Invistico_Airline
return @satisfaction1
end 
go
select dbo.feedback_from_each_customer(10) as feedback_from_each_customer


---xóa function
drop function feedback_from_each_customer


--- Thay đổi các giá trị Null trong cột [Arrival Delay in Minutes] bằng giá trị trung bình của chính nó
update Invistico_Airline
set [Arrival Delay in Minutes] = ISNULL([Arrival Delay in Minutes],  
(select  avg([Arrival Delay in Minutes]) 
from Invistico_Airline 
where satisfaction = 'dissatisfied' ))
where satisfaction = 'dissatisfied'
update Invistico_Airline
set [Arrival Delay in Minutes] = ISNULL([Arrival Delay in Minutes],
(select  avg([Arrival Delay in Minutes]) 
from Invistico_Airline
where satisfaction = 'satisfied' ))
where satisfaction = 'satisfied'

--- Tính giá trị trung bình của các cột
select satisfaction, AVG(information_customer.[Flight Distance]) as mean_of_Flight_Distance ,
AVG([Seat comfort]) as mean_point_of_Seat_comfort,
AVG([Departure/Arrival time convenient]) as mean_point_of_Departure_time_convenient,
AVG([Food and drink]) as mean_point_of_food_and_drink,
AVG([Gate location]) as mean_point_of_gate_location,
AVG([Inflight wifi service]) as mean_point_of_Inflight_wifi_service,
AVG([Inflight entertainment]) mea_point_of_Inflight_entertainment,
AVG([Online support]),AVG([Ease of Online booking]) mean_point_of_Ease_of_Online_booking,
AVG([On-board service]) as mean_point_of_On_board_service,
AVG([Leg room service]) as mean_point_of_leg_room_service,
AVG([Baggage handling]) as mean_point_of_baggage_handling,
AVG([Checkin service]) as mean_point_of_checkin_service,
AVG(Cleanliness) as mean_point_of_Cleanliness,
AVG([Online boarding]) as mean_point_of_Online_boarding,
AVG([Departure Delay in Minutes]) as mean_of_Departure_Delay_in_Minutes,
AVG([Arrival Delay in Minutes] )as mean_of_Arrival_Delay_in_Minutes
from Invistico_Airline
left join information_customer on Invistico_Airline.customer_id = information_customer.customer_id
group by satisfaction
