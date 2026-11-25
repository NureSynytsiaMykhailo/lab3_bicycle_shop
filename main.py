from datetime import date
from pathlib import Path
from typing import Optional

import pyodbc
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

import db

app = FastAPI(
    title="Bicycle Shop API",
)

NOT_FOUND = {50001, 50004}


@app.exception_handler(pyodbc.Error)
async def db_error_handler(request: Request, exc: pyodbc.Error):
    code, msg = db.parse_db_error(exc)
    if code is not None and 50000 <= code < 60000:
        status = 404 if code in NOT_FOUND else 400
        return JSONResponse(status_code=status, content={"code": code, "detail": msg})
    return JSONResponse(status_code=500, content={"code": code, "detail": f"Помилка БД: {msg}"})


@app.get("/api/products", summary="Список товарів")
def products():
    return db.query(
        """SELECT p.id_product, p.Pname, p.article, p.Pprice, p.quantity,
                  ISNULL(SUM(d.number), 0) AS sold
           FROM Product p
           LEFT JOIN Details d ON d.id_product = p.id_product
           GROUP BY p.id_product, p.Pname, p.article, p.Pprice, p.quantity
           ORDER BY p.id_product"""
    )


@app.get("/api/products/{product_id}", summary="Товар і його продажі")
def product_details(product_id: int):
    product = db.query(
        """SELECT id_product, Pname, article, Pprice, quantity, Description
           FROM Product WHERE id_product = ?""",
        (product_id,),
    )
    if not product:
        raise HTTPException(status_code=404, detail="Товар не знайдено")
    sales = db.query(
        """SELECT o.id_order, o.orderDate, o.orderStatus,
                  c.Fname + N' ' + c.Lname AS customer,
                  d.number, d.price, d.number * d.price AS line_sum
           FROM Details d
           JOIN [Order] o ON o.id_order = d.id_order
           JOIN Customer c ON c.id_customer = o.id_customer
           WHERE d.id_product = ?
           ORDER BY o.orderDate DESC, o.id_order DESC""",
        (product_id,),
    )

    return {
        "product": product[0],
        "sales": sales,
        "total_sold": sum(s["number"] for s in sales),
    }


@app.get("/api/customers", summary="Список клієнтів")
def customers():
    return db.query("SELECT id_customer, Fname, Lname FROM Customer ORDER BY id_customer")


class ProductIn(BaseModel):
    name: str = Field(min_length=1)
    price: float = Field(ge=0)
    quantity: int = Field(ge=0)


@app.get("/api/orders", summary="Список замовлень (чеків)")
def orders():
    return db.query(
        """SELECT o.id_order, o.orderDate, o.orderStatus,
                  c.Fname + N' ' + c.Lname AS customer,
                  COUNT(d.id_details) AS items,
                  ISNULL(SUM(d.number * d.price), 0) AS total
           FROM [Order] o
           JOIN Customer c ON c.id_customer = o.id_customer
           LEFT JOIN Details d ON d.id_order = o.id_order
           GROUP BY o.id_order, o.orderDate, o.orderStatus, c.Fname, c.Lname
           ORDER BY o.id_order DESC"""
    )


@app.get("/api/orders/{order_id}", summary="Чек і всі його позиції")
def order_details(order_id: int):
    order = db.query(
        """SELECT o.id_order, o.orderDate, o.orderStatus, o.address,
                  c.Fname + N' ' + c.Lname AS customer, c.email
           FROM [Order] o
           JOIN Customer c ON c.id_customer = o.id_customer
           WHERE o.id_order = ?""",
        (order_id,),
    )
    if not order:
        raise HTTPException(status_code=404, detail="Чек не знайдено")
    items = db.query(
        """SELECT p.Pname, p.article, d.number, d.price, d.number * d.price AS line_sum
           FROM Details d
           JOIN Product p ON p.id_product = d.id_product
           WHERE d.id_order = ?
           ORDER BY d.id_details""",
        (order_id,),
    )
    return {
        "order": order[0],
        "items": items,
        "total": sum(i["line_sum"] for i in items),
    }


@app.post("/api/products", status_code=201, summary="Додати товар (процедура insert_product)")
def add_product(product: ProductIn):
    db.query(
        "EXEC dbo.insert_product @new_name = ?, @new_price = ?, @new_qty = ?",
        (product.name, product.price, product.quantity),
    )
    return {"name": product.name}


class SaleIn(BaseModel):
    product_name: str = Field(min_length=1)
    quantity: int = 1
    order_id: Optional[int] = None
    customer_id: Optional[int] = None


@app.post("/api/sales", status_code=201, summary="Додати продаж, процедура AddSale")
def add_sale(sale: SaleIn):
    rows = db.query(
        "EXEC dbo.AddSale @ProductName = ?, @OrderId = ?, @Quantity = ?, @CustomerId = ?",
        (sale.product_name, sale.order_id, sale.quantity, sale.customer_id),
    )
    return rows[0]


@app.get("/api/functions/most-expensive", summary="Скалярна функція MostExpensiveSold")
def most_expensive(sale_date: date):
    rows = db.query("SELECT dbo.MostExpensiveSold(?) AS result", (sale_date,))
    return {"date": sale_date, "result": rows[0]["result"]}


@app.get("/api/functions/count-goods", summary="Скалярна функція ct_goods")
def count_goods(price: float):
    rows = db.query("SELECT dbo.ct_goods(?) AS result", (price,))
    return {"price": price, "result": rows[0]["result"]}


@app.get("/api/functions/sold-products", summary="Таблична функція SoldProductsByDate")
def sold_products(sale_date: date):
    return db.query("SELECT * FROM dbo.SoldProductsByDate(?)", (sale_date,))


app.mount(
    "/",
    StaticFiles(directory=Path(__file__).resolve().parent / "static", html=True),
    name="static",
)
