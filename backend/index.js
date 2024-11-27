const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");

// Initialize Express app
const app = express();

// Use body-parser to parse JSON requests
app.use(bodyParser.json());

// MongoDB connection
mongoose
  .connect("mongodb://localhost:27017/test_coords", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("Connected to MongoDB"))
  .catch((err) => console.error("Error connecting to MongoDB:", err));

// Create a schema and model for coordinates
const coordsSchema = new mongoose.Schema({
  lat: { type: Number, required: true },
  lng: { type: Number, required: true },
  notes: { type: String, required: true },
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now },
});

const Coords = mongoose.model("Coords", coordsSchema);

app.post("/save-coords", async (req, res) => {
  const { lat, lng, notes } = req.body;

  try {
    const newCoords = new Coords({
      lat,
      lng,
      notes,
      created_at: new Date(),
      updated_at: new Date(),
    });

    await newCoords.save();
    res
      .status(201)
      .json({ message: "Coordinates saved successfully!", data: newCoords });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Failed to save coordinates", error: error.message });
  }
});

app.get("/get-coords", async (req, res) => {
  try {
    const coordsData = await Coords.find();
    res.status(200).json(coordsData);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Failed to fetch coordinates", error: error.message });
  }
});

// Start the server
const port = 3000;
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
