
CREATE TABLE public.inventory (
    id SERIAL PRIMARY KEY,
    quantity INTEGER,
    association_id UUID,
    item_name TEXT
);
