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

const listingImages = {
  car: [
    'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1550355291-bbee04a92027?auto=format&fit=crop&w=1200&q=80',
  ],
  'three-wheeler': [
    'https://images.unsplash.com/photo-1590517862150-930aa1822f9a?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1571210059434-edf0dc48e414?auto=format&fit=crop&w=1200&q=80',
  ],
  van: [
    'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1529369623266-f5264b696110?auto=format&fit=crop&w=1200&q=80',
  ],
  motorbike: [
    'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?auto=format&fit=crop&w=1200&q=80',
  ],
  pickup: [
    'https://images.unsplash.com/photo-1551830820-330a71b99659?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?auto=format&fit=crop&w=1200&q=80',
  ],
  bus: [
    'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?auto=format&fit=crop&w=1200&q=80',
  ],
};

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
           whatsapp_number, preferred_contact_method, status, reviewed_at, expires_at,
           created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, 'Seeded demonstration listing.', ?, ?, ?, ?, ?, ?, ?, 1,
           1, ?, ?, 1, ?, ?, ?, ?, '+94770000000', '+94770000000', 'both', 'active',
           NOW(), DATE_ADD(NOW(), INTERVAL 365 DAY), NOW(), NOW())
         ON DUPLICATE KEY UPDATE title=VALUES(title), category_id=VALUES(category_id),
           available_now=1, status='active', reviewed_at=NOW(),
           expires_at=VALUES(expires_at), updated_at=NOW()`,
        [publicId, provider.id, category.id, listingType, title, manufacturer, model,
          year, capacity, fuel, transmission, airConditioning, price, priceUnit,
          latitude, longitude, area, radius],
      );

      const [listing] = await connection.query(
        'SELECT id FROM listings WHERE public_id=?',
        [publicId],
      );
      await connection.query(
        'DELETE FROM listing_images WHERE listing_id=?',
        [listing.id],
      );
      for (const [sortOrder, imageUrl] of
        (listingImages[categorySlug] || []).entries()) {
        await connection.query(
          `INSERT INTO listing_images
            (listing_id, image_url, thumbnail_url, sort_order, created_at)
           VALUES (?, ?, ?, ?, NOW())`,
          [listing.id, imageUrl, imageUrl, sortOrder],
        );
      }
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
