import app from './main';

const port = process.env.PORT || 3002;

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Server is running on port ${port}`);
});
