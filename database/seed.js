const { pool } = require('../src/config/database');

const providerPublicId = '10000000-0000-4000-8000-000000000001';

const listings = [
  ['20000000-0000-4000-8000-000000000001', 'car', 'vehicle_with_driver', 'Comfortable car with driver in Colombo', 'Toyota', 'Axio', 2017, 4, 'Petrol', 'Automatic', true, 6500, 'per_day', 6.9270790, 79.8612440, 'Colombo', 30],
  ['20000000-0000-4000-8000-000000000002', 'three-wheeler', 'vehicle_with_driver', 'Three Wheeler available in Kandy', 'Bajaj', 'RE', 2020, 3, 'Petrol', 'Manual', false, 120, 'per_km', 7.2905720, 80.6337280, 'Kandy', 20],
  ['20000000-0000-4000-8000-000000000003', 'van', 'vehicle_with_driver', 'Passenger van for tours and airport transfers', 'Toyota', 'KDH', 2016, 10, 'Diesel', 'Automatic', true, 14000, 'per_day', 7.2083040, 79.8358380, 'Negombo', 60],
  ['20000000-0000-4000-8000-000000000004', 'motorbike', 'vehicle_without_driver', 'Motorbike for daily hire in Galle', 'Honda', 'Dio', 2021, 2, 'Petrol', 'Automatic', false, 2500, 'per_day', 6.0328950, 80.2167910, 'Galle', 15],
  ['20000000-0000-4000-8000-000000000005', 'pickup', 'vehicle_with_driver', 'Pickup truck for light goods transport', 'Toyota', 'Hilux', 2015, 4, 'Diesel', 'Manual', true, 9000, 'per_day', 6.0535190, 80.2210010, 'Galle', 50],
  ['20000000-0000-4000-8000-000000000006', 'bus', 'vehicle_with_driver', 'Air-conditioned bus for group trips', 'Ashok Leyland', 'Viking', 2018, 40, 'Diesel', 'Manual', true, 30000, 'per_day', 6.9270790, 79.8612440, 'Colombo', 100],
];

async function seed() {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    await connection.query(
      `INSERT INTO users
        (public_id, email, full_name, phone, whatsapp_number, is_customer, is_provider,
         account_status, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, 0, 1, 'active', NOW(), NOW())
       ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), is_provider=1,
         account_status='active', updated_at=NOW()`,
      [providerPublicId, 'demo-provider@nearride.invalid', 'NearRide Demo Provider', '+94770000000', '+94770000000'],
    );

    const [provider] = await connection.query(
      'SELECT id FROM users WHERE public_id=?',
      [providerPublicId],
    );

    await connection.query(
      `INSERT INTO provider_profiles
        (user_id, display_name, provider_type, description, completed_profile, created_at, updated_at)
       VALUES (?, 'NearRide Demo Provider', 'both', 'Sample provider for demonstration data.', 1, NOW(), NOW())
       ON DUPLICATE KEY UPDATE display_name=VALUES(display_name), provider_type=VALUES(provider_type),
         description=VALUES(description), completed_profile=1, updated_at=NOW()`,
      [provider.id],
    );

    for (const item of listings) {
      const [publicId, categorySlug, listingType, title, manufacturer, model, year,
        capacity, fuel, transmission, airConditioning, price, priceUnit, latitude,
        longitude, area, radius] = item;
      const [category] = await connection.query(
        'SELECT id FROM vehicle_categories WHERE slug=?',
        [categorySlug],
      );
      if (!category) throw new Error(`Missing vehicle category: ${categorySlug}`);

      await connection.query(
        `INSERT INTO listings
          (public_id, provider_id, category_id, listing_type, title, description,
           manufacturer, model, manufactured_year, passenger_capacity, fuel_type,
           transmission_type, has_air_conditioning, available_now,
           long_distance_available, starting_price, price_unit, price_negotiable,
           latitude, longitude, public_area_name, service_radius_km, phone,
           whatsapp_number, preferred_contact_method, status, expires_at,
           created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, 'Seeded demonstration listing.', ?, ?, ?, ?, ?, ?, ?, 1,
           1, ?, ?, 1, ?, ?, ?, ?, '+94770000000', '+94770000000', 'both', 'active',
           DATE_ADD(NOW(), INTERVAL 365 DAY), NOW(), NOW())
         ON DUPLICATE KEY UPDATE title=VALUES(title), category_id=VALUES(category_id),
           available_now=1, status='active', expires_at=VALUES(expires_at), updated_at=NOW()`,
        [publicId, provider.id, category.id, listingType, title, manufacturer, model,
          year, capacity, fuel, transmission, airConditioning, price, priceUnit,
          latitude, longitude, area, radius],
      );
    }

    await connection.commit();
    console.log(`Seeded ${listings.length} demo listings.`);
  } catch (error) {
    if (connection) await connection.rollback();
    throw error;
  } finally {
    if (connection) connection.release();
    await pool.end();
  }
}

seed().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
