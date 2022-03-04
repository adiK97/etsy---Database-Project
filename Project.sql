-- Queries to Create Databases based on normalised the ER diagram
CREATE TABLE user (
    userId VARCHAR(10) PRIMARY KEY,
    email VARCHAR(25),
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25),
    primary_phone NUMBER(10),
    addr VARCHAR(50),
    pwd VARCHAR(30) NOT NULL,
    s_flag NUMBER(1) NOT NULL,
    b_flag NUMBER(1) NOT NULL,
);

CREATE TABLE inbox(
    conversation_id VARCHAR(10) PRIMARY KEY,
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE
);

CREATE TABLE msg(
    message_id VARCHAR(10) PRIMARY KEY,
    message_text VARCHAR(255),
    subj VARCHAR(100),
    conversation_id VARCHAR(10),
    FOREIGN KEY (conversation_id) REFERENCES inbox(conversation_id) ON DELETE CASCADE
);

CREATE TABLE payment_details(
    card_id INTEGER PRIMARY KEY,
    expiry DATE NOT NULL,
    cvv NUMBER(3) NOT NULL,
    zipcode NUMBER(5) NOT NULL,
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE
);

CREATE TABLE product(
    product_id VARCHAR(10) PRIMARY KEY,
    descriptin VARCHAR(50),
    Quantity INTEGER NOT NULL CHECK (Quantity >= 0),
    Color VARCHAR(10),
    Rating NUMBER(10),
    Category VARCHAR(20),
    Listed_price NUMBER(10) NOT NULL
);

CREATE TABLE order(
    order_id VARCHAR(10) PRIMARY KEY,
    order_status VARCHAR(20) NOT NULL,
    total_amount NUMBER(10) NOT NULL,
    delivery_date DATE,
    Placed_on DATE NOT NULL,
    Delivery_addr VARCHAR(50),
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE,
);

CREATE TABLE order_product_list(
    order_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    FOREIGN KEY (oder_id) REFERENCES ORDER(order_id) ON DELETE CASCADE
);

CREATE TABLE shipment(
    shipment_id INTEGER PRIMARY KEY,
    order_id VARCHAR(10) NOT NULL,
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES ORDER(order_id) ON DELETE CASCADE
);

CREATE TABLE favourites(
    collection_id VARCHAR(10) PRIMARY KEY,
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE,
);

CREATE TABLE favourited_products(
    collection_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES USER (product_id) ON DELETE CASCADE,
    FOREIGN KEY (collection_id) REFERENCES FAVOURITES(collection_id) ON DELETE CASCADE
);

CREATE TABLE feedback(
    feedback_id VARCHAR(10) PRIMARY KEY,
    userId VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE
);

CREATE TABLE shopping_cart(
    cart_id VARCHAR(10) PRIMARY KEY,
    userId VARCHAR(10) NOT NULL,
    order_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (userId) REFERENCES USER (userId) ON DELETE CASCADE,
    FOREIGN KEY (order_id) REFERENCES ORDER(order_id) ON DELETE CASCADE
);

CREATE TABLE cart_product_list(
    cart_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    FOREIGN KEY (cart_id) REFERENCES SHOPPING_CART(cart_id) ON DELETE CASCADE
);

CREATE TABLE sells(
    product_id VARCHAR(10) NOT NULL,
    userId VARCHAR(10) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES PRODUCT(product_id) ON DELETE CASCADE,
    FOREIGN KEY (userId) REFERENCES USER(userId) ON DELETE CASCADE
);

-- Procedures
CREATE
OR REPLACE PROCEDURE registerBuyer (
    userId IN VARCHAR,
    email IN VARCHAR,
    first_name IN VARCHAR,
    last_name IN VARCHAR,
    primary_phone IN NUMBER,
    addres in VARCHAR,
    pswd IN VARCHAR
) AS BEGIN
INSERT INTO
    USER
VALUES
    (
        userId,
        email,
        first_name,
        last_name,
        primary_phone,
        addres,
        pswd,
        0,
        1
    );

END registerBuyer;

CREATE
OR REPLACE PROCEDURE registerSeller(
    userId IN VARCHAR,
    email IN VARCHAR,
    first_name IN VARCHAR,
    last_name IN VARCHAR,
    primary_phone IN NUMBER,
    addres in VARCHAR,
    pswd IN VARCHAR
) AS BEGIN
INSERT INTO
    USER
VALUES
    (
        userId,
        email,
        first_name,
        last_name,
        primary_phone,
        addres,
        pswd,
        1,
        0
    );

END registerSeller;

CREATE
OR REPLACE PROCEDURE registerBuyerSeller(
    userId IN VARCHAR,
    email IN VARCHAR,
    first_name IN VARCHAR,
    last_name IN VARCHAR,
    primary_phone IN NUMBER,
    addres in VARCHAR,
    pswd IN VARCHAR
) AS BEGIN
INSERT INTO
    USER
VALUES
    (
        userId,
        email,
        first_name,
        last_name,
        primary_phone,
        addres,
        pswd,
        1,
        1
    );

END registerBuyerSeller;

CREATE
OR REPLACE PROCEDURE addPaymentDetails(
    card_id IN INTEGER,
    expiry IN DATE,
    cvv IN NUMBER,
    zipcode IN NUMBER,
    userId IN VARCHAR
) AS BEGIN
INSERT INTO
    cardDetails
VALUES
    (
        card_id,
        expiry,
        cvv,
        zipcode,
        userId
    );

END addPaymentDetails;

CREATE
OR REPLACE PROCEDURE order (
    v_orderId IN VARCHAR,
    v_userId IN VARCHAR,
    v_shippingPrice IN NUMBER,
    v_deliveryDate IN DATE
) AS v_address INTEGER;

v_listPrice NUMBER := 0;

v_cartTotal NUMBER := 0;

CURSOR prodId IS
SELECT
    cart_product_list.product_id
FROM
    cart_product_list
    INNER JOIN shopping_cart ON cart_product_list.cart_id = shopping_cart.cart_id
WHERE
    userId = v_userId;

pId VARCHAR;

BEGIN OPEN prodId;

LOOP FETCH prodId INTO pId;

EXIT
WHEN prodId % notfound;

SELECT
    Listed_price INTO v_listPrice
FROM
    product
WHERE
    product_id = pId;

v_cartTotal := (v_cartTotal + v_listPrice);

INSERT INTO
    order_product_list
VALUES
    (v_orderId, pId);

END IF;

END LOOP;

CLOSE prodId;

SELECT
    addres INTO v_address
FROM
    user
WHERE
    userId = v_userId;

v_cartTotal := v_cartTotal + v_shippingPrice;

INSERT INTO
    order
VALUES
    (
        v_orderId,
        'Order Placed',
        v_cartTotal,
        v_deliveryDate,
        sysdate,
        v_address,
        v_userId,
    );

END order;

--- Triggers

CREATE
OR REPLACE TRIGGER updateQuantity
AFTER
INSERT
    ON order 
    FOR EACH ROW 
DECLARE 
v_productId INTEGER;
v_quantity INTEGER;

CURSOR prodId IS
SELECT
    product_id
FROM
    order_product_list
WHERE
    order_id = :new.order_id;

BEGIN OPEN prodId;

LOOP FETCH prodId INTO v_productId;

EXIT
WHEN prodId % notfound;

SELECT
    Quantity INTO v_quantity
FROM
    product
WHERE
    product_id = v_productId;

UPDATE
    product
SET
    Quantity = Quantity - 1
WHERE
    product_id = v_productId;

END LOOP;

CLOSE prodId;

END updateQuantity;

CREATE
OR REPLACE TRIGGER emptyCart
AFTER
INSERT
    ON order 
    FOR EACH ROW 
    DECLARE 
BEGIN
DELETE FROM
    shopping_cart
WHERE
    cart_id = :new.cart_id;

DELETE FROM
    cart_product_list
WHERE
    cart_id = :new.cart_id;

END;