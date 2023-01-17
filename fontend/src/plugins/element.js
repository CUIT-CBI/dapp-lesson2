import {
  ElButton,
  ElContainer,
  ElHeader,
  ElAside,
  ElMain
} from 'element-plus'

export default (app) => {
  app.use(ElButton)
  app.use(ElContainer)
  app.use(ElHeader)
  app.use(ElAside)
  app.use(ElMain)
}
